import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:water_fountain_finder/models/local_fountain.dart';
import 'package:water_fountain_finder/utils/geohash_utils.dart';
import 'package:water_fountain_finder/data/fountain_data.dart';

class LocalFountainProvider extends ChangeNotifier {
  List<LocalFountain> _allFountains = [];
  List<LocalFountain> _filteredFountains = [];
  LocalFountain? _selectedFountain;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  Map<String, dynamic> _filters = {};

  // Getters
  List<LocalFountain> get allFountains => _allFountains;
  List<LocalFountain> get filteredFountains => _filteredFountains;
  LocalFountain? get selectedFountain => _selectedFountain;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  int get totalFountainCount => _allFountains.length;
  int get activeFountainCount => _allFountains.where((f) => f.isActive).length;

  LocalFountainProvider() {
    print('🚀 LocalFountainProvider constructor called');
    _loadFountainsFromJson();
  }

  // Load fountains from the local JSON file
  Future<void> _loadFountainsFromJson() async {
    print('🔄 _loadFountainsFromJson method called');
    try {
      _setLoading(true);
      _clearError();

      print('🔄 Loading real fountain data from converted dataset...');
      
      // Get real fountain data from the converted dataset
      final sampleFountains = FountainData.getSampleFountains();
      
      final List<LocalFountain> fountains = [];
      
      // Process each sample fountain
      for (final fountainData in sampleFountains) {
        try {
          final id = fountainData['id'] as String;
          print('🔍 Processing fountain $id: ${fountainData['name']}');
          
          final fountain = LocalFountain.fromJson(id, fountainData);
          print('✅ Fountain parsed successfully: ${fountain.name} at ${fountain.latitude}, ${fountain.longitude}');
          
          // Calculate geohash fields for efficient filtering
          final geohash = GeohashUtils.encode(
            fountain.latitude,
            fountain.longitude,
            precision: 5,
          );
          final geohash4 = GeohashUtils.encode(
            fountain.latitude,
            fountain.longitude,
            precision: 4,
          );
          final geohash3 = GeohashUtils.encode(
            fountain.latitude,
            fountain.longitude,
            precision: 3,
          );
          
          // Create fountain with geohash fields
          final fountainWithGeohash = fountain.copyWithGeohashes(
            geohash: geohash,
            geohash4: geohash4,
            geohash3: geohash3,
          );
          
          fountains.add(fountainWithGeohash);
          print('✅ Fountain added: ${fountainWithGeohash.name}');
          
        } catch (e, stackTrace) {
          print('⚠️ Error processing fountain: $e');
          print('📚 Stack trace: $stackTrace');
        }
      }
      
      _allFountains = fountains;
      _filteredFountains = List.from(_allFountains);
      
      print('✅ Successfully created ${_allFountains.length} sample fountains with geohash data');
      print('📍 Active fountains: ${_allFountains.where((f) => f.isActive).length}');
      
      _setLoading(false);
      notifyListeners();
      
    } catch (e, stackTrace) {
      print('❌ Error creating sample fountains: $e');
      print('📚 Stack trace: $stackTrace');
      _setError('Failed to create sample fountains: $e');
      _setLoading(false);
    }
  }

  // Get fountains in a specific viewport using geohash optimization
  Future<List<LocalFountain>> getFountainsInViewport({
    required double northLat,
    required double southLat,
    required double eastLon,
    required double westLon,
    double? zoomLevel,
  }) async {
    try {
      if (_allFountains.isEmpty) {
        print('⚠️ No fountains loaded yet');
        return [];
      }

      final precision = zoomLevel != null
          ? GeohashUtils.getOptimalPrecision(zoomLevel)
          : 5; // Default to 5-character precision

      print('🔍 Viewport query: N:$northLat, S:$southLat, E:$eastLon, W:$westLon, zoom:$zoomLevel, precision:$precision');

      // Generate geohash prefixes for the viewport
      final geohashPrefixes = GeohashUtils.getViewportGeohashes(
        northLat: northLat,
        southLat: southLat,
        eastLon: eastLon,
        westLon: westLon,
        precision: precision,
      );

      print('🗺️ Generated ${geohashPrefixes.length} geohash prefixes');

      // Filter fountains by geohash prefixes
      final List<LocalFountain> viewportFountains = [];
      final Set<String> seenIds = {};

      for (final fountain in _allFountains) {
        if (!fountain.isActive) continue; // Only show active fountains
        
        String fountainGeohash;
        switch (precision) {
          case 1:
          case 2:
          case 3:
            fountainGeohash = fountain.geohash3;
            break;
          case 4:
            fountainGeohash = fountain.geohash4;
            break;
          default:
            fountainGeohash = fountain.geohash;
        }

        // Check if fountain's geohash matches any of the viewport prefixes
        if (geohashPrefixes.any((prefix) => fountainGeohash.startsWith(prefix))) {
          if (!seenIds.contains(fountain.id)) {
            seenIds.add(fountain.id);
            viewportFountains.add(fountain);
          }
        }
      }

      print('📊 Found ${viewportFountains.length} fountains in viewport');

      // Sort by distance from viewport center
      final centerLat = (northLat + southLat) / 2;
      final centerLon = (eastLon + westLon) / 2;

      viewportFountains.sort((a, b) {
        final distA = _calculateDistance(
          centerLat, centerLon,
          a.latitude, a.longitude,
        );
        final distB = _calculateDistance(
          centerLat, centerLon,
          b.latitude, b.longitude,
        );
        return distA.compareTo(distB);
      });

      // Apply zoom-based limit for performance
      final limit = _calculateOptimalLimit(zoomLevel ?? 10);
      final finalResult = viewportFountains.take(limit).toList();

      print('🎯 Final result: ${finalResult.length} fountains (limited to $limit)');
      return finalResult;

    } catch (e) {
      print('❌ Error in getFountainsInViewport: $e');
      _setError('Failed to load fountains in viewport: $e');
      return [];
    }
  }

  // Get fountains near a specific location
  Future<List<LocalFountain>> getFountainsNearLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    int limit = 50,
  }) async {
    try {
      // Calculate bounding box for the radius
      final latDelta = radiusKm / 111.0; // Approximate km per degree latitude
      final lonDelta = radiusKm / (111.0 * cos(latitude * pi / 180.0)); // Adjust for longitude

      final northLat = latitude + latDelta;
      final southLat = latitude - latDelta;
      final eastLon = longitude + lonDelta;
      final westLon = longitude - lonDelta;

      // Use the viewport method for consistency
      final fountains = await getFountainsInViewport(
        northLat: northLat,
        southLat: southLat,
        eastLon: eastLon,
        westLon: westLon,
        zoomLevel: 14, // High zoom for nearby queries
      );

      return fountains.take(limit).toList();
    } catch (e) {
      print('❌ Error getting fountains near location: $e');
      return [];
    }
  }

  // Search fountains by query
  Future<void> searchFountains(String query) async {
    _searchQuery = query;
    _applyFiltersAndSearch();
  }

  // Apply filters to fountains
  Future<void> applyFilters(Map<String, dynamic> filters) async {
    _filters = filters;
    _applyFiltersAndSearch();
  }

  // Clear all filters
  Future<void> clearFilters() async {
    _filters.clear();
    _applyFiltersAndSearch();
  }

  // Apply filters and search
  void _applyFiltersAndSearch() {
    _filteredFountains = List.from(_allFountains);

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      _filteredFountains = _filteredFountains.where((fountain) {
        final query = _searchQuery.toLowerCase();
        return fountain.name.toLowerCase().contains(query) ||
               fountain.description.toLowerCase().contains(query) ||
               fountain.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    // Apply filters
    if (_filters.isNotEmpty) {
      _filteredFountains = _filteredFountains.where((fountain) {
        for (final entry in _filters.entries) {
          final key = entry.key;
          final value = entry.value;

          switch (key) {
            case 'status':
              if (fountain.status != value) return false;
              break;
            case 'type':
              if (fountain.type != value) return false;
              break;
            case 'waterQuality':
              if (fountain.waterQuality != value) return false;
              break;
            case 'accessibility':
              if (fountain.accessibility != value) return false;
              break;
          }
        }
        return true;
      }).toList();
    }

    notifyListeners();
  }

  // Get fountain by ID
  LocalFountain? getFountainById(String id) {
    try {
      return _allFountains.firstWhere((fountain) => fountain.id == id);
    } catch (e) {
      return null;
    }
  }

  // Set selected fountain
  void selectFountain(LocalFountain fountain) {
    _selectedFountain = fountain;
    notifyListeners();
  }

  // Clear selected fountain
  void clearSelectedFountain() {
    _selectedFountain = null;
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    await _loadFountainsFromJson();
  }

  // Calculate optimal limit based on zoom level
  int _calculateOptimalLimit(double? zoomLevel) {
    if (zoomLevel == null) return 100;
    
    if (zoomLevel >= 18) return 200;      // Street level: more detail
    if (zoomLevel >= 16) return 150;      // Building level
    if (zoomLevel >= 14) return 100;      // Street level
    if (zoomLevel >= 12) return 75;       // City level
    if (zoomLevel >= 10) return 50;       // Region level
    if (zoomLevel >= 8) return 25;        // Country level
    return 10;                            // Continent level: fewer results
  }

  // Calculate distance between two points using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
          final a = sin(dLat / 2) * sin(dLat / 2) +
          cos(lat1 * pi / 180.0) * cos(lat2 * pi / 180.0) *
          sin(dLon / 2) * sin(dLon / 2);
      
      final c = 2 * atan(sqrt(a) / sqrt(1 - a));
    
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
