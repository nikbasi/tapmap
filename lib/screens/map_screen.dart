import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
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
  MapboxMapController? _mapController;
  List<Fountain> _nearbyFountains = [];
  Fountain? _selectedFountain;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _loadNearbyFountains();
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
    if (_mapController == null || !_isMapReady) return;

    for (final fountain in _nearbyFountains) {
      _mapController!.addSymbol(
        SymbolOptions(
          geometry: LatLng(
            fountain.location.latitude,
            fountain.location.longitude,
          ),
          iconImage: _getFountainIcon(fountain),
          iconSize: 1.2,
          iconAllowOverlap: true,
        ),
        {
          'fountainId': fountain.id,
          'fountain': fountain,
        },
      );
    }
  }

  String _getFountainIcon(Fountain fountain) {
    switch (fountain.type) {
      case FountainType.fountain:
        return 'fountain-icon';
      case FountainType.tap:
        return 'tap-icon';
      case FountainType.refillStation:
        return 'refill-icon';
      default:
        return 'fountain-icon';
    }
  }

  void _onMapCreated(MapboxMapController controller) {
    _mapController = controller;
    _isMapReady = true;
    _addFountainMarkers();
  }

  void _onMapClick(Point<double> point, LatLng coordinates) {
    // Deselect fountain when clicking on empty map area
    setState(() {
      _selectedFountain = null;
    });
  }

  void _onSymbolTapped(Symbol symbol) {
    final fountain = symbol.data['fountain'] as Fountain;
    setState(() {
      _selectedFountain = fountain;
    });
  }

  void _onCameraIdle() {
    // Reload fountains when map stops moving
    _loadNearbyFountains();
  }

  void _goToCurrentLocation() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final position = await locationProvider.getCurrentLocation();
    
    if (position != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          AppConfig.defaultZoom,
        ),
      );
    }
  }

  void _searchNearby() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final position = locationProvider.currentPosition;
    
    if (position != null) {
      await _loadNearbyFountains();
      
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            AppConfig.defaultZoom,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          MapboxMap(
            accessToken: AppConfig.mapboxAccessToken,
            styleString: AppConfig.mapboxStyleUrl,
            onMapCreated: _onMapCreated,
            onMapClick: _onMapClick,
            onSymbolTapped: _onSymbolTapped,
            onCameraIdle: _onCameraIdle,
            initialCameraPosition: CameraPosition(
              target: LatLng(0, 0), // Will be updated with user location
              zoom: AppConfig.defaultZoom,
            ),
            myLocationEnabled: true,
            myLocationTrackingMode: MyLocationTrackingMode.Tracking,
            myLocationRenderMode: MyLocationRenderMode.COMPASS,
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
          Consumer<LocationProvider>(
            builder: (context, locationProvider, child) {
              return IconButton(
                onPressed: locationProvider.hasLocationPermission
                    ? _goToCurrentLocation
                    : () => locationProvider.requestLocationPermission(),
                icon: Icon(
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
      child: IconButton(
        onPressed: _goToCurrentLocation,
        icon: const Icon(
          Icons.my_location,
          color: AppColors.primary,
        ),
        tooltip: 'Current location',
      ),
    );
  }
}
