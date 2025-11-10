import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/map_result.dart';
import '../services/fountain_api_service.dart';

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

  @override
  void initState() {
    super.initState();
    // Load initial data after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _loadFountainsForVisibleArea();
    });
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

  /// Calculate visible bounds from center and zoom
  LatLngBounds _calculateBounds(LatLng center, double zoom) {
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

  /// Load fountains for the currently visible map area
  Future<void> _loadFountainsForVisibleArea() async {
    if (_isLoading) return;

    // Calculate bounds from current center and zoom
    final bounds = _calculateBounds(_currentCenter, _currentZoom);

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _apiService.getFountainsForMapView(
        minLat: bounds.south,
        maxLat: bounds.north,
        minLng: bounds.west,
        maxLng: bounds.east,
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
              if (event is MapEventMoveEnd) {
                // Update current center from map controller
                final camera = _mapController.camera;
                if (camera != null) {
                  _currentCenter = camera.center;
                  _currentZoom = camera.zoom;
                  _debouncedLoadFountains();
                }
              }
            },
          ),
          children: [
            // OpenStreetMap tile layer
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.tapmap',
              maxZoom: 19,
            ),
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
                    child: _buildClusterMarker(result),
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
                    child: _buildFountainMarker(result),
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
      ],
    );
  }
}

