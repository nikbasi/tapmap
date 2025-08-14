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
  bool _isSatelliteView = false; // Track map type

  @override
  void initState() {
    super.initState();
    _loadNearbyFountains();
    _initializeMapWithUserLocation();
    
    // Listen to location changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      locationProvider.addListener(_onLocationChanged);
    });
  }

  @override
  void dispose() {
    // Remove listener
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    locationProvider.removeListener(_onLocationChanged);
    super.dispose();
  }

  void _onLocationChanged() {
    // Update markers when location changes
    _addFountainMarkers();
  }

  void _toggleMapType() {
    setState(() {
      _isSatelliteView = !_isSatelliteView;
    });
  }

  Future<void> _initializeMapWithUserLocation() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final position = locationProvider.currentPosition;
    
    if (position != null) {
      // Center map on user's location
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        AppConfig.defaultZoom,
      );
    }
  }

  Future<void> _loadNearbyFountains() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final position = locationProvider.currentPosition;
    
    if (position != null) {
      final fountainProvider = Provider.of<FountainProvider>(context, listen: false);
      final fountains = await fountainProvider.loadFountainsNearLocation(
        position.latitude,
        position.longitude,
        AppConfig.searchRadiusKm,
      );
      
      setState(() {
        _nearbyFountains = fountains;
      });
      
      _addFountainMarkers();
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
            child: Icon(
              _getFountainIcon(fountain),
              color: Colors.blue,
              size: 30,
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
    // Deselect fountain when clicking on empty map area
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
      // Smoothly center map on user's current location
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        AppConfig.defaultZoom,
      );
      
      // Reload fountains at current location
      await _loadNearbyFountains();
    }
  }

  void _searchNearby() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final position = locationProvider.currentPosition;
    
    if (position != null) {
      await _loadNearbyFountains();
    }
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
                    // Attributions API changed in flutter_map 6.x
                    // Provide attributions via nonRotatedChildren with an Align widget if needed
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

          // Current location button
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 100,
            right: AppSizes.paddingM,
            child: _buildCurrentLocationButton(),
          ),

          // Map type toggle button
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 180,
            right: AppSizes.paddingM,
            child: _buildMapTypeToggleButton(),
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
            child: GestureDetector(
              onTap: _searchNearby,
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
                      'Search nearby fountains...',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.paddingS),
          // Map type toggle button
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

  Widget _buildCurrentLocationButton() {
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
      child: Consumer<LocationProvider>(
        builder: (context, locationProvider, child) {
          return IconButton(
            onPressed: locationProvider.isLoading ? null : _goToCurrentLocation,
            icon: locationProvider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : const Icon(
                    Icons.my_location,
                    color: AppColors.primary,
                  ),
            tooltip: 'Current location',
          );
        },
      ),
    );
  }

  Widget _buildMapTypeToggleButton() {
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
      child: IconButton(
        onPressed: _toggleMapType,
        icon: Icon(
          _isSatelliteView ? Icons.map : Icons.satellite,
          color: _isSatelliteView ? AppColors.accent : AppColors.primary,
        ),
        tooltip: _isSatelliteView ? 'Switch to street view' : 'Switch to satellite view',
      ),
    );
  }
}
