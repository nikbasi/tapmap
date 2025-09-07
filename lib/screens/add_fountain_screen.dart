import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:water_fountain_finder/providers/auth_provider.dart';
import 'package:water_fountain_finder/providers/postgres_fountain_provider.dart';
import 'package:water_fountain_finder/providers/location_provider.dart';
import 'package:water_fountain_finder/models/fountain.dart';
import 'package:water_fountain_finder/models/postgres_fountain.dart';
import 'package:water_fountain_finder/utils/constants.dart';
import 'package:water_fountain_finder/utils/geohash_utils.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:convert';

class AddFountainScreen extends StatefulWidget {
  const AddFountainScreen({super.key});

  @override
  State<AddFountainScreen> createState() => _AddFountainScreenState();
}

class _AddFountainScreenState extends State<AddFountainScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  FountainType _selectedType = FountainType.fountain;
  WaterQuality _selectedWaterQuality = WaterQuality.unknown;
  Accessibility _selectedAccessibility = Accessibility.public;
  final List<String> _selectedTags = [];
  final List<String> _photoUrls = [];
  
  bool _isLoading = false;
  bool _useCurrentLocation = true;
  
  // Map-related variables
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  List<Marker> _mapMarkers = [];

  final List<String> _availableTags = [
    '24h',
    'wheelchair_accessible',
    'cold_water',
    'hot_water',
    'filtered',
    'bottle_fill',
    'indoor',
    'outdoor',
    'parking_nearby',
    'restroom_nearby',
  ];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final position = locationProvider.currentPosition;
    
    if (position != null) {
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _updateMapMarkers();
      });
    }
  }

  void _updateMapMarkers() {
    if (_selectedLocation != null) {
      _mapMarkers = [
        Marker(
          point: _selectedLocation!,
          width: 40,
          height: 40,
                      child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            child: const Icon(
              Icons.location_on,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ];
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng coordinates) {
    setState(() {
      _selectedLocation = coordinates;
      _useCurrentLocation = false;
      _updateMapMarkers();
    });
    
    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Location set to: ${coordinates.latitude.toStringAsFixed(6)}, ${coordinates.longitude.toStringAsFixed(6)}',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Removed unused method

  Future<void> _setToCurrentLocation() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final position = await locationProvider.getCurrentLocation();
    
    if (position != null) {
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _useCurrentLocation = true;
        _updateMapMarkers();
      });
      
      // Center the map on the new location
      _mapController.move(
        _selectedLocation!,
        15.0,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to get current location. Please check location permissions.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _centerMapOnSelectedLocation() {
    if (_selectedLocation != null) {
      _mapController.move(
        _selectedLocation!,
        15.0,
      );
    }
  }

  void _clearSelectedLocation() {
    setState(() {
      _selectedLocation = null;
      _mapMarkers.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location cleared. Please select a new location on the map.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image != null) {
      // TODO: Upload image to Firebase Storage and get URL
      setState(() {
        _photoUrls.add('temp_url_${_photoUrls.length}');
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image != null) {
      // TODO: Upload image to Firebase Storage and get URL
      setState(() {
        _photoUrls.add('temp_url_${_photoUrls.length}');
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photoUrls.removeAt(index);
    });
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _submitFountain() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate that a location is selected
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location on the map before submitting.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      _showAuthenticationDialog();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      double latitude = _selectedLocation!.latitude;
      double longitude = _selectedLocation!.longitude;

      final fountain = Fountain(
        id: '', // Will be generated by PostgreSQL
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        latitude: latitude,
        longitude: longitude,
        type: _selectedType,
        status: FountainStatus.active,
        waterQuality: _selectedWaterQuality,
        accessibility: _selectedAccessibility,
        addedBy: authProvider.currentUserId ?? 'anonymous',
        addedDate: DateTime.now(),
        validations: [],
        photos: _photoUrls,
        tags: _selectedTags,
      );

      final fountainProvider = Provider.of<PostgresFountainProvider>(context, listen: false);
      final success = await fountainProvider.addFountain(PostgresFountain.fromFountain(fountain));

      if (success && mounted) {
        _showSuccessDialog();
        _resetForm();
      } else {
        final error = fountainProvider.error ?? 'Failed to add fountain';
        throw Exception(error);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _nameController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedType = FountainType.fountain;
      _selectedWaterQuality = WaterQuality.unknown;
      _selectedAccessibility = Accessibility.public;
      _selectedTags.clear();
      _photoUrls.clear();
      _useCurrentLocation = true;
      _selectedLocation = null;
      _mapMarkers.clear();
    });
    
    // Reinitialize location
    _initializeLocation();
  }

  void _showAuthenticationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Required'),
        content: const Text(
          'You need to sign in to add new fountains. This helps us maintain data quality and track contributions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to sign in screen
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success!'),
        content: const Text(
          'Your fountain has been added successfully! It will be reviewed by our community and should appear on the map soon.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text('Failed to add fountain: $error'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.addFountain),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              _buildSectionTitle('Basic Information'),
              _buildTextField(
                controller: _nameController,
                label: 'Fountain Name',
                hint: 'e.g., Central Park Water Fountain',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a fountain name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.paddingM),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Describe the fountain, its location, or any special features...',
                maxLines: 3,
              ),

              const SizedBox(height: AppSizes.paddingL),

              // Fountain Type
              _buildSectionTitle('Fountain Type'),
              _buildDropdown<FountainType>(
                value: _selectedType,
                items: FountainType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),

              const SizedBox(height: AppSizes.paddingM),

              // Water Quality
              _buildSectionTitle('Water Quality'),
              _buildDropdown<WaterQuality>(
                value: _selectedWaterQuality,
                items: WaterQuality.values.map((quality) {
                  return DropdownMenuItem(
                    value: quality,
                    child: Text(quality.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedWaterQuality = value!;
                  });
                },
              ),

              const SizedBox(height: AppSizes.paddingM),

              // Accessibility
              _buildSectionTitle('Accessibility'),
              _buildDropdown<Accessibility>(
                value: _selectedAccessibility,
                items: Accessibility.values.map((accessibility) {
                  return DropdownMenuItem(
                    value: accessibility,
                    child: Text(accessibility.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAccessibility = value!;
                  });
                },
              ),

              const SizedBox(height: AppSizes.paddingL),

              // Location
              _buildSectionTitle('Location'),
              _buildLocationSection(),

              const SizedBox(height: AppSizes.paddingL),

              // Tags
              _buildSectionTitle('Tags'),
              _buildTagsSection(),

              const SizedBox(height: AppSizes.paddingL),

              // Photos
              _buildSectionTitle('Photos (Optional)'),
              _buildPhotosSection(),

              const SizedBox(height: AppSizes.paddingXL),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitFountain,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add Fountain'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingS),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      children: [
        // Location toggle
        Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: _useCurrentLocation,
              onChanged: (value) {
                setState(() {
                  _useCurrentLocation = value!;
                  if (value) {
                    _initializeLocation();
                  }
                });
              },
            ),
            const Text('Use current location'),
            const Spacer(),
            Radio<bool>(
              value: false,
              groupValue: _useCurrentLocation,
              onChanged: (value) {
                setState(() {
                  _useCurrentLocation = value!;
                });
              },
            ),
            const Text('Select on map'),
          ],
        ),

        const SizedBox(height: AppSizes.paddingM),
        
        // Interactive map for location selection
        Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            child: _buildLocationMap(),
          ),
        ),

        const SizedBox(height: AppSizes.paddingM),

        // Location instructions and controls
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: AppSizes.paddingS),
                  Expanded(
                    child: Text(
                      'Tap anywhere on the map to set the fountain location.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
                      const SizedBox(height: AppSizes.paddingM),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _setToCurrentLocation,
                icon: const Icon(Icons.my_location, size: 18),
                label: const Text('Set to Current Location'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.paddingM),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _centerMapOnSelectedLocation,
                icon: const Icon(Icons.center_focus_strong, size: 18),
                label: const Text('Center Map'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                ),
              ),
            ),
          ],
        ),
              const SizedBox(height: AppSizes.paddingM),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _selectedLocation != null ? _clearSelectedLocation : null,
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Clear Selected Location'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_selectedLocation != null) ...[
          const SizedBox(height: AppSizes.paddingM),
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: AppSizes.paddingS),
                Text(
                  'Location selected',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.paddingM),
          Row(
            children: [
              Expanded(
                child: _buildCoordinateDisplay(
                  'Latitude',
                  _selectedLocation!.latitude.toStringAsFixed(6),
                  Icons.north,
                ),
              ),
              const SizedBox(width: AppSizes.paddingM),
              Expanded(
                child: _buildCoordinateDisplay(
                  'Longitude',
                  _selectedLocation!.longitude.toStringAsFixed(6),
                  Icons.east,
                ),
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: AppSizes.paddingM),
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: AppSizes.paddingS),
                Text(
                  'Please select a location on the map',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationMap() {
    final initialCenter = _selectedLocation ?? 
        const LatLng(40.7128, -74.0060); // Default to NYC if no location set
    
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 15.0,
            onTap: _onMapTap,
            minZoom: 10.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: AppConfig.osmTileUrl,
              userAgentPackageName: 'com.example.water_fountain_finder',
            ),
            MarkerLayer(markers: _mapMarkers),
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
        
        // Zoom controls
        Positioned(
          right: AppSizes.paddingM,
          bottom: AppSizes.paddingM,
          child: Column(
            children: [
                              FloatingActionButton.small(
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      (currentZoom + 1).clamp(10.0, 18.0),
                    );
                  },
                  heroTag: 'zoom_in',
                  child: const Icon(Icons.add),
                ),
              const SizedBox(height: AppSizes.paddingS),
                              FloatingActionButton.small(
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      (currentZoom - 1).clamp(10.0, 18.0),
                    );
                  },
                  heroTag: 'zoom_out',
                  child: const Icon(Icons.remove),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoordinateDisplay(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    return Wrap(
      spacing: AppSizes.paddingS,
      runSpacing: AppSizes.paddingS,
      children: _availableTags.map((tag) {
        final isSelected = _selectedTags.contains(tag);
        return FilterChip(
          label: Text(tag.replaceAll('_', ' ')),
          selected: isSelected,
          onSelected: (selected) => _toggleTag(tag),
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
          checkmarkColor: AppColors.primary,
        );
      }).toList(),
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
              ),
            ),
            const SizedBox(width: AppSizes.paddingM),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose Photo'),
              ),
            ),
          ],
        ),
        if (_photoUrls.isNotEmpty) ...[
          const SizedBox(height: AppSizes.paddingM),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _photoUrls.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: AppSizes.paddingS),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppSizes.radiusM),
                          color: Colors.grey.shade200,
                        ),
                        child: const Icon(
                          Icons.image,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removePhoto(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
