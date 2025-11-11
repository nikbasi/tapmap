import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/map_result.dart';
import '../models/fountain.dart';
import '../models/fountain_filters.dart';
import '../services/fountain_api_service.dart';
import 'fountain_filter_sheet.dart';

enum MapType { satellite, street }

class FountainMap extends StatefulWidget {
  const FountainMap({super.key});

  @override
  State<FountainMap> createState() => _FountainMapState();
}

class _FountainMapState extends State<FountainMap> {
  final MapController _mapController = MapController();
  final FountainApiService _apiService = FountainApiService();
  final List<MapResult> _mapResults = [];
  Timer? _debounceTimer;
  bool _isLoading = false;
  LatLng _currentCenter = const LatLng(37.7749, -122.4194);
  double _currentZoom = 10.0;
  MapType _mapType = MapType.satellite; // Default to satellite view
  FountainFilters _filters = FountainFilters.empty();

  @override
  void initState() {
    super.initState();
    // Request location and center map on user location
    _requestLocationAndCenter();
  }

  /// Request location permission and center map on user's location
  Future<void> _requestLocationAndCenter() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      // Load fountains for default location
      Future.delayed(const Duration(milliseconds: 500), () {
        _loadFountainsForVisibleArea();
      });
      return;
    }

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        // Load fountains for default location
        Future.delayed(const Duration(milliseconds: 500), () {
          _loadFountainsForVisibleArea();
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      // Load fountains for default location
      Future.delayed(const Duration(milliseconds: 500), () {
        _loadFountainsForVisibleArea();
      });
      return;
    }

    // Get current position
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() {
          _currentCenter = LatLng(position.latitude, position.longitude);
          _currentZoom = 14.0; // Zoom in closer when showing user location
        });

        // Move map to user location
        _mapController.move(_currentCenter, _currentZoom);

        // Load fountains for the new location
        Future.delayed(const Duration(milliseconds: 500), () {
          _loadFountainsForVisibleArea();
        });
      }
    } catch (e) {
      print('Error getting location: $e');
      // Load fountains for default location
      Future.delayed(const Duration(milliseconds: 500), () {
        _loadFountainsForVisibleArea();
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  /// Calculate area in km² from map bounds
  double _calculateArea(LatLngBounds bounds) {
    final latRange = bounds.north - bounds.south;
    final lngRange = bounds.east - bounds.west;
    final centerLat = (bounds.north + bounds.south) / 2;
    
    // Approximate area in km²
    // 1 degree latitude ≈ 111 km
    // 1 degree longitude ≈ 111 km * cos(latitude)
    final areaKm2 = latRange * 111.0 * lngRange * 111.0 * 
                    math.cos(centerLat * math.pi / 180).abs();
    
    return areaKm2;
  }

  /// Get geohash precision based on zoom level
  /// This matches the database function logic
  int _getGeohashPrecisionForZoom(double zoom) {
    // Approximate area calculation based on zoom
    // Zoom 0 = world, zoom 18 = street level
    if (zoom <= 3) return 2;      // World/continent
    if (zoom <= 5) return 3;      // Large country
    if (zoom <= 7) return 4;      // Country/state
    if (zoom <= 9) return 5;      // Region
    if (zoom <= 11) return 6;     // City
    if (zoom <= 13) return 7;     // District
    return 8;                     // Neighborhood/individual
  }

  /// Calculate visible bounds from center and zoom (fallback when map size is unknown)
  LatLngBounds _calculateBoundsFallback(LatLng center, double zoom) {
    // Approximate degrees per pixel at given zoom
    // At zoom 0: ~360 degrees / 256 pixels = 1.40625 degrees per pixel
    // Each zoom level doubles the resolution
    final degreesPerPixel = 360.0 / (256 * (1 << zoom.toInt()));
    
    // Assume viewport is roughly 400x400 pixels (adjust based on screen size)
    final latDelta = degreesPerPixel * 200;
    final lngDelta = degreesPerPixel * 200;
    
    return LatLngBounds(
      LatLng(center.latitude - latDelta, center.longitude - lngDelta),
      LatLng(center.latitude + latDelta, center.longitude + lngDelta),
    );
  }

  /// Try to get the actual visible bounds from the map controller
  LatLngBounds? _getActualVisibleBounds() {
    try {
      return _mapController.camera.visibleBounds;
    } catch (_) {
      return null;
    }
  }

  /// Load fountains for the currently visible map area
  Future<void> _loadFountainsForVisibleArea() async {
    if (_isLoading) return;

    // Prefer actual visible bounds from the map; fall back to approximation if unavailable
    final bounds = _getActualVisibleBounds() ??
        _calculateBoundsFallback(_currentCenter, _currentZoom);

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _apiService.getFountainsForMapView(
        minLat: bounds.south,
        maxLat: bounds.north,
        minLng: bounds.west,
        maxLng: bounds.east,
        filters: _filters.hasActiveFilters ? _filters : null,
      );

      if (mounted) {
        setState(() {
          _mapResults.clear();
          _mapResults.addAll(results);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading fountains: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Debounced version of load function
  void _debouncedLoadFountains() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadFountainsForVisibleArea();
    });
  }

  /// Get the appropriate tile layer based on current map type
  TileLayer _getTileLayer() {
    if (_mapType == MapType.satellite) {
      // Esri World Imagery - free satellite imagery
      return TileLayer(
        urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
        userAgentPackageName: 'com.example.tapmap',
        maxZoom: 19,
      );
    } else {
      // OpenStreetMap for street view
      return TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.example.tapmap',
        maxZoom: 19,
      );
    }
  }

  /// Show filter bottom sheet
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return FountainFilterSheet(
          initialFilters: _filters,
          onFiltersChanged: (FountainFilters newFilters) {
            setState(() {
              _filters = newFilters;
            });
            // Reload fountains with new filters
            _loadFountainsForVisibleArea();
          },
        );
      },
    );
  }

  /// Toggle between satellite and street map types
  void _toggleMapType() {
    setState(() {
      _mapType = _mapType == MapType.satellite ? MapType.street : MapType.satellite;
    });
  }

  /// Open Google Maps with directions to the fountain location
  Future<void> _openGoogleMapsDirections(Fountain fountain) async {
    try {
      // Get current user location for starting point
      Position? userPosition;
      try {
        userPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
      } catch (e) {
        print('Could not get user location: $e');
        // Continue without user location - Google Maps will use current location
      }

      final destLat = fountain.latitude;
      final destLng = fountain.longitude;
      final name = Uri.encodeComponent(fountain.name);
      
      Uri googleMapsUrl;
      
      if (userPosition != null) {
        // Include user location as starting point for directions
        final originLat = userPosition.latitude;
        final originLng = userPosition.longitude;
        googleMapsUrl = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLng&destination=$destLat,$destLng&destination_place_id=$name'
        );
      } else {
        // Fallback: just show destination (Google Maps will use current location)
        googleMapsUrl = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&destination_place_id=$name'
        );
      }
      
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(
          googleMapsUrl,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Cannot launch Google Maps URL');
      }
    } catch (e) {
      // Show error message if launch fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open Google Maps: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Show fountain details in a bottom sheet
  void _showFountainDetails(Fountain fountain) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // Header with icon
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.water_drop,
                                color: Colors.blue,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fountain.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (fountain.status != null)
                                    Text(
                                      fountain.status!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: fountain.status == 'active'
                                            ? Colors.green
                                            : Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Details section
                        _buildDetailRow(
                          icon: Icons.location_on,
                          label: 'Location',
                          value: '${fountain.latitude.toStringAsFixed(6)}, ${fountain.longitude.toStringAsFixed(6)}',
                        ),
                        if (fountain.waterQuality != null)
                          _buildDetailRow(
                            icon: Icons.water,
                            label: 'Water Quality',
                            value: fountain.waterQuality!,
                          ),
                        if (fountain.accessibility != null)
                          _buildDetailRow(
                            icon: Icons.accessible,
                            label: 'Accessibility',
                            value: fountain.accessibility!,
                          ),
                        const SizedBox(height: 24),
                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _openGoogleMapsDirections(fountain);
                                  Navigator.pop(context); // Close bottom sheet
                                },
                                icon: const Icon(Icons.directions),
                                label: const Text('Directions'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.close),
                                label: const Text('Close'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Build a detail row widget
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build cluster marker widget
  Widget _buildClusterMarker(MapResult result) {
    if (result.type != MapResultType.count || result.cluster == null) {
      return const SizedBox.shrink();
    }

    final cluster = result.cluster!;
    final count = cluster.count;

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.7),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          count > 999 ? '999+' : count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Build individual fountain marker widget
  Widget _buildFountainMarker(MapResult result) {
    if (result.type != MapResultType.fountain || result.fountain == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
      ),
      child: const Icon(
        Icons.water_drop,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentCenter,
            initialZoom: _currentZoom,
            minZoom: 3.0,
            maxZoom: 18.0,
            onMapEvent: (MapEvent event) {
              // Update current camera state and debounce fountain loading
              // Only update on move/zoom end events
              if (event is MapEventMoveEnd) {
                final camera = _mapController.camera;
                _currentCenter = camera.center;
                _currentZoom = camera.zoom;
                _debouncedLoadFountains();
              }
            },
          ),
          children: [
            // Dynamic tile layer (satellite or street)
            _getTileLayer(),
            // Markers layer
            MarkerLayer(
              markers: _mapResults.map((result) {
                if (result.type == MapResultType.count && result.cluster != null) {
                  return Marker(
                    point: LatLng(
                      result.cluster!.centerLat,
                      result.cluster!.centerLng,
                    ),
                    width: 60,
                    height: 60,
                    child: GestureDetector(
                      onTap: () {
                        // Zoom in when cluster is tapped
                        _mapController.move(
                          LatLng(
                            result.cluster!.centerLat,
                            result.cluster!.centerLng,
                          ),
                          _currentZoom + 2,
                        );
                      },
                      child: _buildClusterMarker(result),
                    ),
                  );
                } else if (result.type == MapResultType.fountain && 
                          result.fountain != null) {
                  return Marker(
                    point: LatLng(
                      result.fountain!.latitude,
                      result.fountain!.longitude,
                    ),
                    width: 30,
                    height: 30,
                    child: GestureDetector(
                      onTap: () => _showFountainDetails(result.fountain!),
                      child: _buildFountainMarker(result),
                    ),
                  );
                }
                return const Marker(point: LatLng(0, 0), child: SizedBox.shrink());
              }).toList(),
            ),
          ],
        ),
        // Loading indicator
        if (_isLoading)
          const Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        // Map type toggle button
        Positioned(
          top: 20,
          right: 20,
          child: FloatingActionButton.small(
            onPressed: _toggleMapType,
            tooltip: _mapType == MapType.satellite ? 'Switch to Street View' : 'Switch to Satellite View',
            child: Icon(
              _mapType == MapType.satellite ? Icons.map : Icons.satellite,
            ),
          ),
        ),
        // Filter button
        Positioned(
          top: 20,
          right: 80,
          child: FloatingActionButton.small(
            onPressed: _showFilterSheet,
            tooltip: 'Filter fountains',
            backgroundColor: _filters.hasActiveFilters ? Colors.blue : null,
            child: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_filters.hasActiveFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

