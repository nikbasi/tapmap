import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:water_fountain_finder/providers/fountain_provider.dart';
import 'package:water_fountain_finder/providers/location_provider.dart';
import 'package:water_fountain_finder/models/fountain.dart';
import 'package:water_fountain_finder/utils/constants.dart';
import 'package:water_fountain_finder/widgets/fountain_info_card.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Fountain> _nearbyFountains = [];
  Fountain? _selectedFountain;
  final List<Marker> _markers = [];
  final MapController _mapController = MapController();
  bool _isSatelliteView = false;

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
      } catch (e) {
        print('Map not ready yet: $e');
      }
    }
  }

  // Simple method to load fountains in current map area
  Future<void> _loadFountainsInMapArea() async {
    try {
      final fountainProvider = Provider.of<FountainProvider>(context, listen: false);
      
      // Get current map bounds
      final bounds = _mapController.bounds;
      final zoom = _mapController.zoom;
      
      print('=== DEBUGGING FOUNTAIN LOADING ===');
      print('Map zoom: $zoom');
      print('Map bounds: $bounds');
      
      if (bounds != null) {
        print('NorthEast: ${bounds.northEast.latitude}, ${bounds.northEast.longitude}');
        print('SouthWest: ${bounds.southWest.latitude}, ${bounds.southWest.longitude}');
        
        // Calculate viewport area
        final latSpan = bounds.northEast.latitude - bounds.southWest.latitude;
        final lonSpan = bounds.northEast.longitude - bounds.southWest.longitude;
        final areaSqKm = latSpan * lonSpan * 111.0 * 111.0;
        print('Viewport area: ${areaSqKm.toStringAsFixed(2)} km²');
        
        // Load fountains in the current map area
        final fountains = await fountainProvider.getFountainsInViewport(
          northLat: bounds.northEast.latitude,
          southLat: bounds.southWest.latitude,
          eastLon: bounds.northEast.longitude,
          westLon: bounds.southWest.longitude,
          zoomLevel: zoom,
        );
        
        print('Query returned ${fountains.length} fountains');
        
        setState(() {
          _nearbyFountains = fountains;
        });
        
        _addFountainMarkers();
        
        // Show result
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Found ${fountains.length} fountains in this area'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('Map bounds are NULL - this is the problem!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Map not ready yet. Please wait a moment and try again.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error loading fountains: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading fountains: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _addFountainMarkers() {
    _markers.clear();
    
    // Add user location marker
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final userPosition = locationProvider.currentPosition;
    
    if (userPosition != null) {
      _markers.add(
        Marker(
          point: LatLng(userPosition.latitude, userPosition.longitude),
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.my_location,
              color: AppColors.primary,
              size: 24,
            ),
          ),
        ),
      );
    }
    
    // Add fountain markers
    for (final fountain in _nearbyFountains) {
      _markers.add(
        Marker(
          point: LatLng(
            fountain.location.latitude,
            fountain.location.longitude,
          ),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _onMarkerTapped(fountain),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: Icon(
                _getFountainIcon(fountain),
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }
    
    setState(() {});
  }

  IconData _getFountainIcon(Fountain fountain) {
    switch (fountain.type) {
      case FountainType.fountain:
        return Icons.water_drop;
      case FountainType.tap:
        return Icons.tap_and_play;
      case FountainType.refillStation:
        return Icons.local_drink;
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng coordinates) {
    setState(() {
      _selectedFountain = null;
    });
  }

  void _onMarkerTapped(Fountain fountain) {
    setState(() {
      _selectedFountain = fountain;
    });
  }

  void _goToCurrentLocation() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final position = await locationProvider.getCurrentLocation();
    
    if (position != null) {
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        AppConfig.defaultZoom,
      );
    }
  }

  void _toggleMapType() {
    setState(() {
      _isSatelliteView = !_isSatelliteView;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          Consumer<LocationProvider>(
            builder: (context, locationProvider, child) {
              final userPosition = locationProvider.currentPosition;
              final initialCenter = userPosition != null 
                  ? LatLng(userPosition.latitude, userPosition.longitude)
                  : const LatLng(40.7128, -74.0060); // Default to NYC if no user location
              
              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: AppConfig.defaultZoom,
                  onTap: _onMapTap,
                ),
                children: [
                  TileLayer(
                    urlTemplate: _isSatelliteView 
                        ? AppConfig.esriSatelliteUrl 
                        : AppConfig.osmTileUrl,
                    userAgentPackageName: 'com.example.water_fountain_finder',
                  ),
                  MarkerLayer(markers: _markers),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        _isSatelliteView 
                            ? AppConfig.esriSatelliteAttribution 
                            : AppConfig.osmAttribution,
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          // Top app bar
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSizes.paddingM,
            left: AppSizes.paddingM,
            right: AppSizes.paddingM,
            child: _buildTopBar(),
          ),

          // Load fountains button
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 100,
            right: AppSizes.paddingM,
            child: _buildLoadFountainsButton(),
          ),

          // Fountain info card
          if (_selectedFountain != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 100,
              left: AppSizes.paddingM,
              right: AppSizes.paddingM,
              child: FountainInfoCard(
                fountain: _selectedFountain!,
                onClose: () {
                  setState(() {
                    _selectedFountain = null;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingM,
        vertical: AppSizes.paddingS,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingM,
                vertical: AppSizes.paddingS,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: AppSizes.paddingS),
                  Text(
                    'Tap the button below to find fountains in this area',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSizes.paddingS),
          IconButton(
            onPressed: _toggleMapType,
            icon: Icon(
              _isSatelliteView ? Icons.map : Icons.satellite,
              color: _isSatelliteView ? AppColors.accent : AppColors.primary,
            ),
            tooltip: _isSatelliteView ? 'Switch to street view' : 'Switch to satellite view',
          ),
          const SizedBox(width: AppSizes.paddingS),
          Consumer<LocationProvider>(
            builder: (context, locationProvider, child) {
              return IconButton(
                onPressed: locationProvider.hasLocationPermission
                    ? (locationProvider.isLoading ? null : _goToCurrentLocation)
                    : () => locationProvider.requestLocationPermission(),
                icon: locationProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    : Icon(
                        locationProvider.hasLocationPermission
                            ? Icons.my_location
                            : Icons.location_off,
                        color: locationProvider.hasLocationPermission
                            ? AppColors.primary
                            : Colors.grey,
                      ),
                tooltip: 'Go to current location',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadFountainsButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fountain count display
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingS,
              vertical: AppSizes.paddingXS,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: Text(
              '${_nearbyFountains.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Load fountains button
          IconButton(
            onPressed: _loadFountainsInMapArea,
            icon: const Icon(
              Icons.water_drop,
              color: AppColors.primary,
              size: 32,
            ),
            tooltip: 'Find fountains in this map area',
          ),
        ],
      ),
    );
  }
}
