import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:water_fountain_finder/models/fountain.dart';
import 'package:water_fountain_finder/models/user.dart';
import 'package:water_fountain_finder/providers/auth_provider.dart';
import 'package:water_fountain_finder/utils/geohash_utils.dart';

class FountainProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Fountain> _fountains = [];
  List<Fountain> _filteredFountains = [];
  Fountain? _selectedFountain;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  Map<String, dynamic> _filters = {};

  // Getters
  List<Fountain> get fountains => _fountains;
  List<Fountain> get filteredFountains => _filteredFountains;
  Fountain? get selectedFountain => _selectedFountain;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  // Simple check for Firebase availability
  bool get isFirebaseAvailable {
    try {
      _firestore.app.name;
      return true;
    } catch (e) {
      return false;
    }
  }

  // Manually trigger fountain loading (useful for retrying after Firebase initialization)
  Future<void> retryLoadFountains() async {
    if (isFirebaseAvailable) {
      await _loadFountains();
    }
  }

  FountainProvider() {
    // Only load fountains if Firebase is available
    if (isFirebaseAvailable) {
      _loadFountains();
    }
  }

  // Load all fountains
  Future<void> _loadFountains() async {
    try {
      _setLoading(true);
      _clearError();

      final querySnapshot = await _firestore
          .collection('fountains')
          .where('status', isEqualTo: 'active')
          .orderBy('addedDate', descending: true)
          .get();

      _fountains = querySnapshot.docs
          .map((doc) => Fountain.fromFirestore(doc))
          .toList();

      // Initialize filtered fountains with all fountains
      _filteredFountains = List.from(_fountains);
      notifyListeners();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load fountains: $e');
      _setLoading(false);
    }
  }

  // Load all fountains from the database (useful for testing and viewing imported data)
  Future<List<Fountain>> getAllFountains() async {
    try {
      _setLoading(true);
      _clearError();

      final querySnapshot = await _firestore
          .collection('fountains')
          .where('status', isEqualTo: 'active')
          .orderBy('addedDate', descending: true)
          .get();

      final allFountains = querySnapshot.docs
          .map((doc) => Fountain.fromFirestore(doc))
          .toList();

      _setLoading(false);
      return allFountains;
    } catch (e) {
      _setError('Failed to load all fountains: $e');
      _setLoading(false);
      return [];
    }
  }

  // Get fountains in a specific viewport using geohash
  Future<List<Fountain>> getFountainsInViewport({
    required double northLat,
    required double southLat,
    required double eastLon,
    required double westLon,
    double? zoomLevel,
  }) async {
    try {
      print('🔍 getFountainsInViewport called with bounds: N:$northLat, S:$southLat, E:$eastLon, W:$westLon, zoom:$zoomLevel');
      
      final precision = zoomLevel != null
          ? GeohashUtils.getOptimalPrecision(zoomLevel)
          : 5; // Default to 5-character precision (~1.2km)

      print('📍 Using precision: $precision');

      final geohashPrefixes = GeohashUtils.getViewportGeohashes(
        northLat: northLat,
        southLat: southLat,
        eastLon: eastLon,
        westLon: westLon,
        precision: precision,
      );

      print('🗺️ Generated ${geohashPrefixes.length} geohash prefixes: ${geohashPrefixes.take(5).join(', ')}...');

      if (geohashPrefixes.isEmpty) {
        print('❌ No geohash prefixes generated');
        return [];
      }

      final allResults = <Fountain>[];
      final Set<String> seenIds = {};

      for (final geohashPrefix in geohashPrefixes) {
        try {
          String geohashField;
          switch (precision) {
            case 1:
            case 2:
            case 3:
              geohashField = 'geohash3';
              break;
            case 4:
              geohashField = 'geohash4';
              break;
            default:
              geohashField = 'geohash'; // Fixed: Python script created 'geohash', not 'geohash5'
          }

          print('🔍 Querying for geohash prefix: $geohashPrefix using field: $geohashField');

          final querySnapshot = await _firestore
              .collection('fountains')
              .where('status', isEqualTo: 'active')
              .where(geohashField, isEqualTo: geohashPrefix)
              .get();

          print('📊 Query returned ${querySnapshot.docs.length} documents for prefix $geohashPrefix');
          
          // Debug: Show the actual query being made
          print('🔍 Query details: status=active AND $geohashField=$geohashPrefix');

          for (final doc in querySnapshot.docs) {
            final fountain = Fountain.fromFirestore(doc);
            if (!seenIds.contains(fountain.id)) {
              seenIds.add(fountain.id);
              allResults.add(fountain);
            }
          }
        } catch (e) {
          print('❌ Error querying prefix $geohashPrefix: $e');
          continue;
        }
      }

      print('📈 Total unique fountains found: ${allResults.length}');

      final centerLat = (northLat + southLat) / 2;
      final centerLon = (eastLon + westLon) / 2;

      allResults.sort((a, b) {
        final distA = _calculateDistance(
          centerLat, centerLon,
          a.location.latitude, a.location.longitude,
        );
        final distB = _calculateDistance(
          centerLat, centerLon,
          b.location.latitude, b.location.longitude,
        );
        return distA.compareTo(distB);
      });

      final limit = _calculateOptimalLimit(zoomLevel ?? 10);
      final finalResult = allResults.take(limit).toList();

      print('🎯 Final result: ${finalResult.length} fountains (limited to $limit)');
      return finalResult;
    } catch (e) {
      print('❌ Error in getFountainsInViewport: $e');
      _setError('Failed to load fountains in viewport: $e');
      return [];
    }
  }

  // Get fountains in a specific region
  Future<List<Fountain>> getFountainsByRegion({
    required double northLat,
    required double southLat,
    required double eastLon,
    required double westLon,
    int limit = 100,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Use the same geohash-based approach for consistency
      final fountains = await getFountainsInViewport(
        northLat: northLat,
        southLat: southLat,
        eastLon: eastLon,
        westLon: westLon,
        zoomLevel: 10, // Medium zoom for region queries
      );

      _setLoading(false);
      return fountains.take(limit).toList();
    } catch (e) {
      _setError('Failed to load fountains by region: $e');
      _setLoading(false);
      return [];
    }
  }

  // Get fountains near a specific location
  Future<List<Fountain>> loadFountainsNearLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    int limit = 50,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Calculate bounding box for the radius
      final latDelta = radiusKm / 111.0; // Approximate km per degree latitude
      final lonDelta = radiusKm / (111.0 * cos(latitude * pi / 180.0)); // Adjust for longitude

      final northLat = latitude + latDelta;
      final southLat = latitude - latDelta;
      final eastLon = longitude + lonDelta;
      final westLon = longitude - lonDelta;

      // Use the same geohash-based approach
      final fountains = await getFountainsInViewport(
        northLat: northLat,
        southLat: southLat,
        eastLon: eastLon,
        westLon: westLon,
        zoomLevel: 14, // High zoom for nearby queries
      );

      _setLoading(false);
      return fountains.take(limit).toList();
    } catch (e) {
      _setError('Failed to load fountains near location: $e');
      _setLoading(false);
      return [];
    }
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
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan(sqrt(a) / sqrt(1 - a));
    
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  // Update fountains with geohash fields (for existing data)
  Future<void> updateFountainsWithGeohash() async {
    try {
      _setLoading(true);
      _clearError();

      // Get all fountains that don't have geohash fields
      final querySnapshot = await _firestore
          .collection('fountains')
          .where('geohash', isNull: true)
          .limit(500) // Process in batches
          .get();

      if (querySnapshot.docs.isEmpty) {
        _setLoading(false);
        return;
      }

      final batch = _firestore.batch();
      int updatedCount = 0;

      for (final doc in querySnapshot.docs) {
        final fountain = Fountain.fromFirestore(doc);
        
        // Calculate geohash fields
        final geohash = GeohashUtils.encode(
          fountain.location.latitude,
          fountain.location.longitude,
          precision: 5,
        );
        final geohash4 = GeohashUtils.encode(
          fountain.location.latitude,
          fountain.location.longitude,
          precision: 4,
        );
        final geohash3 = GeohashUtils.encode(
          fountain.location.latitude,
          fountain.location.longitude,
          precision: 3,
        );

        // Update the document
        batch.update(doc.reference, {
          'geohash': geohash,
          'geohash4': geohash4,
          'geohash3': geohash3,
        });

        updatedCount++;
      }

      // Commit the batch
      await batch.commit();

      _setLoading(false);
    } catch (e) {
      _setError('Failed to update fountains with geohash: $e');
      _setLoading(false);
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
    _filteredFountains = List.from(_fountains);

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
  Future<Fountain?> getFountainById(String id) async {
    try {
      final doc = await _firestore.collection('fountains').doc(id).get();
      if (doc.exists) {
        return Fountain.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      _setError('Failed to get fountain: $e');
      return null;
    }
  }

  // Add new fountain
  Future<bool> addFountain(Fountain fountain, AuthProvider authProvider) async {
    try {
      _setLoading(true);
      _clearError();

      // Calculate geohash fields
      final geohash = GeohashUtils.encode(
        fountain.location.latitude,
        fountain.location.longitude,
        precision: 5,
      );
      final geohash4 = GeohashUtils.encode(
        fountain.location.latitude,
        fountain.location.longitude,
        precision: 4,
      );
      final geohash3 = GeohashUtils.encode(
        fountain.location.latitude,
        fountain.location.longitude,
        precision: 3,
      );

      // Add geohash fields to fountain data
      final fountainData = fountain.toFirestore();
      fountainData['geohash'] = geohash;
      fountainData['geohash4'] = geohash4;
      fountainData['geohash3'] = geohash3;

      await _firestore.collection('fountains').add(fountainData);

      // Reload fountains
      await _loadFountains();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add fountain: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update existing fountain
  Future<bool> updateFountain(Fountain fountain) async {
    try {
      _setLoading(true);
      _clearError();

      // Recalculate geohash fields if location changed
      final geohash = GeohashUtils.encode(
        fountain.location.latitude,
        fountain.location.longitude,
        precision: 5,
      );
      final geohash4 = GeohashUtils.encode(
        fountain.location.latitude,
        fountain.location.longitude,
        precision: 4,
      );
      final geohash3 = GeohashUtils.encode(
        fountain.location.latitude,
        fountain.location.longitude,
        precision: 3,
      );

      // Add geohash fields to fountain data
      final fountainData = fountain.toFirestore();
      fountainData['geohash'] = geohash;
      fountainData['geohash4'] = geohash4;
      fountainData['geohash3'] = geohash3;

      await _firestore.collection('fountains').doc(fountain.id).update(fountainData);

      // Reload fountains
      await _loadFountains();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update fountain: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete fountain
  Future<bool> deleteFountain(String id) async {
    try {
      _setLoading(true);
      _clearError();

      await _firestore.collection('fountains').doc(id).delete();

      // Reload fountains
      await _loadFountains();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete fountain: $e');
      _setLoading(false);
      return false;
    }
  }

  // Set selected fountain
  void selectFountain(Fountain fountain) {
    _selectedFountain = fountain;
    notifyListeners();
  }

  // Clear selected fountain
  void clearSelectedFountain() {
    _selectedFountain = null;
    notifyListeners();
  }

  // Add missing methods that are referenced in other files
  Future<void> refresh() async {
    await _loadFountains();
  }

  Future<void> refreshData() async {
    await _loadFountains();
  }

  // Debug method to check what's in the database
  Future<void> debugCheckDatabase() async {
    try {
      print('🔍 DEBUG: Checking database contents...');
      
      // Check total count of all fountains
      final totalQuery = await _firestore
          .collection('fountains')
          .get();
      
      print('📊 TOTAL fountains in database: ${totalQuery.docs.length}');
      
      // Check count of active fountains
      final activeQuery = await _firestore
          .collection('fountains')
          .where('status', isEqualTo: 'active')
          .get();
      
      print('✅ ACTIVE fountains: ${activeQuery.docs.length}');
      
      // Check count of fountains with geohash fields
      final geohash3Query = await _firestore
          .collection('fountains')
          .where('geohash3', isNull: false)
          .get();
      
      print('🔍 Fountains with geohash3 field: ${geohash3Query.docs.length}');
      
      final geohash4Query = await _firestore
          .collection('fountains')
          .where('geohash4', isNull: false)
          .get();
      
      print('🔍 Fountains with geohash4 field: ${geohash4Query.docs.length}');
      
      final geohash5Query = await _firestore
          .collection('fountains')
          .where('geohash', isNull: false)
          .get();
      
      print('🔍 Fountains with geohash field: ${geohash5Query.docs.length}');
      
      // Check a few random fountains to see what fields they have
      final sampleQuery = await _firestore
          .collection('fountains')
          .where('status', isEqualTo: 'active')
          .limit(5)
          .get();
      
      print('📄 Sample fountains:');
      
      for (final doc in sampleQuery.docs) {
        final data = doc.data();
        final location = data['location'] as GeoPoint;
        print('📄 Fountain ${doc.id}:');
        print('   - name: ${data['name']}');
        print('   - location: lat:${location.latitude}, lon:${location.longitude}');
        print('   - geohash: ${data['geohash']}');
        print('   - geohash4: ${data['geohash4']}');
        print('   - geohash3: ${data['geohash3']}');
        print('   - status: ${data['status']}');
        print('   - importSource: ${data['importSource']}');
        print('   ---');
      }
      
      // Check if there are fountains without geohash fields
      final noGeohashQuery = await _firestore
          .collection('fountains')
          .where('geohash3', isNull: true)
          .limit(3)
          .get();
      
      if (noGeohashQuery.docs.isNotEmpty) {
        print('⚠️ Found fountains WITHOUT geohash fields:');
        for (final doc in noGeohashQuery.docs) {
          final data = doc.data();
          print('   - ${doc.id}: ${data['name']} at ${data['location']}');
        }
      }
      
      // Test a specific geohash query to see if it works
      print('🧪 Testing specific geohash query...');
      try {
        final testQuery = await _firestore
            .collection('fountains')
            .where('status', isEqualTo: 'active')
            .where('geohash3', isEqualTo: 'sr7')
            .limit(1)
            .get();
        
        print('✅ Test query for geohash3=sr7 returned: ${testQuery.docs.length} results');
        if (testQuery.docs.isNotEmpty) {
          final testDoc = testQuery.docs.first;
          final testData = testDoc.data();
          print('   Found: ${testData['name']} at ${testData['location']}');
        }
      } catch (e) {
        print('❌ Test query for geohash3=sr7 failed: $e');
      }
      
      // Test alternative field names
      print('🧪 Testing alternative field names...');
      try {
        final testQuery2 = await _firestore
            .collection('fountains')
            .where('status', isEqualTo: 'active')
            .where('geohash', isEqualTo: 'sr7bh')
            .limit(1)
            .get();
        
        print('✅ Test query for geohash=sr7bh returned: ${testQuery2.docs.length} results');
        if (testQuery2.docs.isNotEmpty) {
          final testDoc = testQuery2.docs.first;
          final testData = testDoc.data();
          print('   Found: ${testData['name']} at ${testData['location']}');
        }
      } catch (e) {
        print('❌ Test query for geohash=sr7bh failed: $e');
      }
      
      // Test a simple query without geohash to see if basic queries work
      print('🧪 Testing basic query without geohash...');
      try {
        final basicQuery = await _firestore
            .collection('fountains')
            .where('status', isEqualTo: 'active')
            .limit(1)
            .get();
        
        print('✅ Basic query returned: ${basicQuery.docs.length} results');
        if (basicQuery.docs.isNotEmpty) {
          final testDoc = basicQuery.docs.first;
          final testData = testDoc.data();
          print('   Found: ${testData['name']} at ${testData['location']}');
          print('   All fields: ${testData.keys.toList()}');
        }
      } catch (e) {
        print('❌ Basic query failed: $e');
      }
      
    } catch (e) {
      print('❌ Error checking database: $e');
    }
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
