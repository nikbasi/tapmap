import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:water_fountain_finder/providers/postgres_fountain_provider.dart';
import 'package:water_fountain_finder/providers/location_provider.dart';
import 'package:water_fountain_finder/models/postgres_fountain.dart';
import 'package:water_fountain_finder/models/fountain.dart';
import 'package:water_fountain_finder/utils/constants.dart';
import 'package:water_fountain_finder/widgets/fountain_info_card.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<PostgresFountain> _visibleFountains = [];
  PostgresFountain? _selectedFountain;
  final List<Marker> _markers = [];
  final MapController _mapController = MapController();
  bool _isSatelliteView = false;
  bool _isLoadingFountains = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    // Wait for the map to be fully initialized
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (!mounted) return;
    
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final position = locationProvider.currentPosition;
    
    if (position != null) {
      try {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          AppConfig.defaultZoom,
        );
        
        // Wait a bit more for the map to settle, then load fountains
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          await _loadFountainsInMapArea();
        }
      } catch (e) {
        print('Map initialization error: $e');
      }
    } else {
      // If no user location, move to default location and try to load fountains
      try {
        _mapController.move(
          AppConfig.defaultLocation,
          AppConfig.defaultZoom,
        );
        
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          await _loadFountainsInMapArea();
        }
      } catch (e) {
        print('Map initialization error: $e');
      }
    }
  }

  Future<void> _loadFountainsInMapArea() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isLoadingFountains = true;
      });

      final bounds = _mapController.bounds;
      if (bounds == null) {
        print('Map bounds not available yet');
        return;
      }

      final fountainProvider = Provider.of<PostgresFountainProvider>(context, listen: false);
      
      final result = await fountainProvider.getFountainsInViewport(
        northLat: bounds.northEast.latitude,
        southLat: bounds.southWest.latitude,
        eastLon: bounds.northEast.longitude,
        westLon: bounds.southWest.longitude,
        zoomLevel: _mapController.zoom,
      );
      
      print('📱 Received ${result.length} fountains, creating markers...');
      
      if (mounted) {
        setState(() {
          _visibleFountains = result;
          _addFountainMarkers();
          _isLoadingFountains = false;
        });
      }
    } catch (e) {
      print('❌ Error loading fountains in map area: $e');
      if (mounted) {
        setState(() {
          _isLoadingFountains = false;
        });
      }
    }
  }

  void _addFountainMarkers() {
    _markers.clear();
    
    for (final fountain in _visibleFountains) {
      _markers.add(
        Marker(
          point: fountain.location,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showFountainInfo(fountain),
            child: Container(
              decoration: BoxDecoration(
                color: fountain.isActive ? Colors.green : Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _getFountainIcon(fountain.type),
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }
    
    print('📱 Created ${_markers.length} markers for ${_visibleFountains.length} fountains');
  }

  // Build a styled cluster bubble showing the count
  Widget _buildClusterBubble(int count) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.blue.shade600,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  IconData _getFountainIcon(FountainType type) {
    switch (type) {
      case FountainType.fountain:
        return Icons.water_drop;
      case FountainType.tap:
        return Icons.tap_and_play;
      case FountainType.refillStation:
        return Icons.local_drink;
    }
  }

  void _showFountainInfo(PostgresFountain fountain) {
    setState(() {
      _selectedFountain = fountain;
    });
  }

  void _hideFountainInfo() {
    setState(() {
      _selectedFountain = null;
    });
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    _hideFountainInfo();
  }

  void _onMapMoved(MapPosition position, bool hasGesture) {
    if (hasGesture) {
      // Debounce map movement to avoid too many API calls
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _loadFountainsInMapArea();
        }
      });
    }
  }

  void _toggleSatelliteView() {
    setState(() {
      _isSatelliteView = !_isSatelliteView;
    });
  }

  void _refreshFountains() async {
    await _loadFountainsInMapArea();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: AppConfig.defaultLocation,
              initialZoom: AppConfig.defaultZoom,
              onMapReady: () {
                // Map is ready
              },
              onTap: _onMapTap,
              onPositionChanged: _onMapMoved,
            ),
            children: [
              TileLayer(
                urlTemplate: _isSatelliteView 
                    ? AppConfig.satelliteTileUrl 
                    : AppConfig.streetTileUrl,
                userAgentPackageName: 'com.example.water_fountain_finder',
              ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  markers: _markers,
                  maxClusterRadius: 45,
                  size: const Size(42, 42),
                  fitBoundsOptions: const FitBoundsOptions(padding: EdgeInsets.all(50)),
                  builder: (context, markers) => _buildClusterBubble(markers.length),
                  spiderfyCircleRadius: 40,
                  spiderfySpiralDistanceMultiplier: 1.0,
                  circleSpiralSwitchover: 9,
                  zoomToBoundsOnClick: true,
                ),
              ),
            ],
          ),
          
          // Top bar with controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            right: 10,
            child: Row(
              children: [
                // Toggle satellite view
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _toggleSatelliteView,
                    icon: Icon(
                      _isSatelliteView ? Icons.map : Icons.satellite,
                      color: _isSatelliteView ? Colors.blue : Colors.grey,
                    ),
                    tooltip: _isSatelliteView ? 'Switch to Map' : 'Switch to Satellite',
                  ),
                ),
                
                const SizedBox(width: 10),
                
                // Refresh button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _refreshFountains,
                    icon: Icon(
                      Icons.refresh,
                      color: _isLoadingFountains ? Colors.grey : Colors.blue,
                    ),
                    tooltip: 'Refresh Fountains',
                  ),
                ),
                
                const Spacer(),
                
                // Fountain count indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.water_drop,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_visibleFountains.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Loading indicator
          if (_isLoadingFountains)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Loading fountains...',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          
          // Selected fountain info card
          if (_selectedFountain != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: FountainInfoCard(
                fountain: _selectedFountain!,
                onClose: _hideFountainInfo,
              ),
            ),
        ],
      ),
    );
  }
}
