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
  bool _isMapReady = false;
  final List<Marker> _markers = [];

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
    _markers.clear();
    
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
      default:
        return Icons.water_drop;
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
      // For now, just reload fountains at current location
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
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(0, 0), // Will be updated with user location
              initialZoom: AppConfig.defaultZoom,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: AppConfig.osmTileUrl,
                userAgentPackageName: 'com.example.water_fountain_finder',
                // Attributions API changed in flutter_map 6.x
                // Provide attributions via nonRotatedChildren with an Align widget if needed
              ),
              MarkerLayer(markers: _markers),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    AppConfig.osmAttribution,
                    onTap: () {},
                  ),
                ],
              ),
            ],
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
