import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:water_fountain_finder/models/postgres_fountain.dart';
import 'package:water_fountain_finder/models/fountain.dart';
import 'package:water_fountain_finder/services/postgres_service.dart';
import 'package:water_fountain_finder/utils/geohash_utils.dart';
import 'package:water_fountain_finder/config/database_config.dart';

class PostgresFountainProvider extends ChangeNotifier {
  // API configuration
  static const String _apiBaseUrl = 'http://localhost:8000';
  
  List<PostgresFountain> _fountains = [];
  List<PostgresFountain> _filteredFountains = [];
  PostgresFountain? _selectedFountain;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  Map<String, dynamic> _filters = {};
  
  // Connection status
  bool _isConnected = false;
  String _connectionStatus = 'disconnected';

  // Getters
  List<PostgresFountain> get fountains => _fountains;
  List<PostgresFountain> get filteredFountains => _filteredFountains;
  PostgresFountain? get selectedFountain => _selectedFountain;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  bool get isConnected => _isConnected;
  String get connectionStatus => _connectionStatus;

  // Initialize the provider
  PostgresFountainProvider() {
    _initializeWithAPI();
  }

  // Initialize with API connection
  Future<void> _initializeWithAPI() async {
    try {
      print('🗺️ Initializing PostgresFountainProvider with API connection...');
      _setLoading(true);
      _setConnectionStatus('connecting');
      
      // Test API connection
      print('🗺️ Testing API connection to $_apiBaseUrl...');
      final response = await http.get(Uri.parse('$_apiBaseUrl/health'))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        _isConnected = true;
        _setConnectionStatus('connected');
        print('🗺️ Successfully connected to FastAPI backend');
        print('🗺️ Health check response: ${response.body}');
        
        // Load real fountains from API
        await _loadFountainsFromAPI();
      } else {
        _setConnectionStatus('connection_failed');
        _setError('Failed to connect to API. Status: ${response.statusCode}');
        print('🗺️ API connection failed (${response.statusCode}), using mock data');
        
        // Fallback to mock data if API connection fails
        await _loadMockFountains();
        _setConnectionStatus('mock_data_fallback');
      }
    } catch (e) {
      print('🗺️ Initialization error: $e');
      _setConnectionStatus('error');
      _setError('Failed to initialize: $e');
      
      // Fallback to mock data on error
      await _loadMockFountains();
      _setConnectionStatus('mock_data_error_fallback');
    } finally {
      _setLoading(false);
    }
  }

  // Load fountains from API
  Future<void> _loadFountainsFromAPI() async {
    try {
      print('🗺️ Loading fountains from FastAPI backend...');
      _setLoading(true);
      _clearError();

      // Query all fountains from the API
      print('🗺️ Making API request to $_apiBaseUrl/fountains');
      final response = await http.get(Uri.parse('$_apiBaseUrl/fountains'))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        print('🗺️ API response received, status: ${response.statusCode}');
        print('🗺️ Response headers: ${response.headers}');
        print('🗺️ Response body length: ${response.body.length}');
        
        final List<dynamic> jsonData = json.decode(response.body);
        
        if (jsonData.isNotEmpty) {
          _fountains = jsonData.map((json) => PostgresFountain.fromMap(json)).toList();
          _filteredFountains = List.from(_fountains);
          print('🗺️ Loaded ${_fountains.length} fountains from API');
        } else {
          _fountains = [];
          _filteredFountains = [];
        }
      } else {
        throw Exception('API returned status ${response.statusCode}');
      }
      
      notifyListeners();
      _setLoading(false);
    } catch (e) {
      print('🗺️ API loading error: $e');
      _setError('Failed to load fountains from API: $e');
      _setLoading(false);
      
      // Fallback to mock data on API error
      await _loadMockFountains();
    }
  }

  // Load mock fountains (fallback)
  Future<void> _loadMockFountains() async {
    try {
      _setLoading(true);
      _clearError();

      // Create mock fountain data in Rome area
      _fountains = [
        PostgresFountain(
          id: '1',
          name: 'Trevi Fountain',
          description: 'Famous Baroque fountain in the heart of Rome',
          latitude: 41.9009,
          longitude: 12.4833,
          type: FountainType.fountain,
          status: FountainStatus.active,
          waterQuality: WaterQuality.potable,
          accessibility: Accessibility.public,
          addedBy: 'admin',
          addedDate: DateTime.now().subtract(const Duration(days: 30)),
          photos: ['https://example.com/photo1.jpg'],
          tags: ['outdoor', '24h', 'wheelchair_accessible', 'historic'],
          rating: 4.8,
          reviewCount: 1250,
          importSource: 'manual',
          importDate: DateTime.now().subtract(const Duration(days: 30)),
          osmData: {'osm_id': '12345'},
          geohash: 'sr2',
          geohash_4: 'sr2',
          geohash_3: 'sr2',
        ),
        PostgresFountain(
          id: '2',
          name: 'Piazza Navona Fountains',
          description: 'Three beautiful fountains in Piazza Navona',
          latitude: 41.8994,
          longitude: 12.4731,
          type: FountainType.fountain,
          status: FountainStatus.active,
          waterQuality: WaterQuality.potable,
          accessibility: Accessibility.public,
          addedBy: 'admin',
          addedDate: DateTime.now().subtract(const Duration(days: 25)),
          photos: ['https://example.com/photo2.jpg'],
          tags: ['outdoor', 'historic', 'scenic', 'piazza'],
          rating: 4.6,
          reviewCount: 890,
          importSource: 'manual',
          importDate: DateTime.now().subtract(const Duration(days: 25)),
          osmData: {'osm_id': '12346'},
          geohash: 'sr2',
          geohash_4: 'sr2',
          geohash_3: 'sr2',
        ),
        PostgresFountain(
          id: '3',
          name: 'Vatican Museum Water Station',
          description: 'Modern water refill station near Vatican Museums',
          latitude: 41.9069,
          longitude: 12.4539,
          type: FountainType.refillStation,
          status: FountainStatus.active,
          waterQuality: WaterQuality.potable,
          accessibility: Accessibility.public,
          addedBy: 'admin',
          addedDate: DateTime.now().subtract(const Duration(days: 20)),
          photos: ['https://example.com/photo3.jpg'],
          tags: ['indoor', 'filtered', 'bottle_fill', 'museum'],
          rating: 4.4,
          reviewCount: 320,
          importSource: 'manual',
          importDate: DateTime.now().subtract(const Duration(days: 20)),
          osmData: {'osm_id': '12347'},
          geohash: 'sr2',
          geohash_4: 'sr2',
          geohash_3: 'sr2',
        ),
        PostgresFountain(
          id: '4',
          name: 'Colosseum Water Tap',
          description: 'Public water tap near the Colosseum',
          latitude: 41.8902,
          longitude: 12.4922,
          type: FountainType.tap,
          status: FountainStatus.active,
          waterQuality: WaterQuality.potable,
          accessibility: Accessibility.public,
          addedBy: 'admin',
          addedDate: DateTime.now().subtract(const Duration(days: 15)),
          photos: ['https://example.com/photo4.jpg'],
          tags: ['outdoor', 'historic', 'tourist', 'parking_nearby'],
          rating: 4.3,
          reviewCount: 567,
          importSource: 'manual',
          importDate: DateTime.now().subtract(const Duration(days: 15)),
          osmData: {'osm_id': '12348'},
          geohash: 'sr2',
          geohash_4: 'sr2',
          geohash_3: 'sr2',
        ),
        PostgresFountain(
          id: '5',
          name: 'Spanish Steps Fountain',
          description: 'Elegant fountain at the base of Spanish Steps',
          latitude: 41.9058,
          longitude: 12.4828,
          type: FountainType.fountain,
          status: FountainStatus.active,
          waterQuality: WaterQuality.potable,
          accessibility: Accessibility.public,
          addedBy: 'admin',
          addedDate: DateTime.now().subtract(const Duration(days: 10)),
          photos: ['https://example.com/photo5.jpg'],
          tags: ['outdoor', 'scenic', 'historic', 'shopping'],
          rating: 4.5,
          reviewCount: 743,
          importSource: 'manual',
          importDate: DateTime.now().subtract(const Duration(days: 10)),
          osmData: {'osm_id': '12349'},
          geohash: 'sr2',
          geohash_4: 'sr2',
          geohash_3: 'sr2',
        ),
      ];
      
      _filteredFountains = List.from(_fountains);
      
      print('🗺️ Loaded ${_fountains.length} mock fountains');
      notifyListeners();
      _setLoading(false);
    } catch (e) {
      print('🗺️ Mock fountain error: $e');
      _setError('Failed to load mock fountains: $e');
      _setLoading(false);
    }
  }

  // Refresh data
  Future<void> refresh() async {
    if (_isConnected) {
      await _loadFountainsFromAPI();
    } else {
      await _loadMockFountains();
    }
  }

  // Refresh data (alias for compatibility)
  Future<void> refreshData() async {
    await refresh();
  }

  // Apply filters
  void applyFilters([Map<String, dynamic>? filters]) {
    if (filters != null) {
      _setFilters(filters);
    }
    
    _filteredFountains = _fountains.where((fountain) {
      // Search query filter
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        matchesSearch = fountain.name.toLowerCase().contains(query) ||
                       fountain.description.toLowerCase().contains(query) ||
                       fountain.tags.any((tag) => tag.toLowerCase().contains(query));
      }

      // Type filter
      bool matchesType = true;
      if (_filters.containsKey('type')) {
        matchesType = fountain.type.name == _filters['type'];
      }

      // Status filter
      bool matchesStatus = true;
      if (_filters.containsKey('status')) {
        matchesStatus = fountain.status.name == _filters['status'];
      }

      // Water quality filter
      bool matchesWaterQuality = true;
      if (_filters.containsKey('waterQuality')) {
        matchesWaterQuality = fountain.waterQuality.name == _filters['waterQuality'];
      }

      // Accessibility filter
      bool matchesAccessibility = true;
      if (_filters.containsKey('accessibility')) {
        matchesAccessibility = fountain.accessibility.name == _filters['accessibility'];
      }

      // Tags filter
      bool matchesTags = true;
      if (_filters.containsKey('tags') && _filters['tags'] is List) {
        final selectedTags = List<String>.from(_filters['tags']);
        matchesTags = selectedTags.any((tag) => fountain.tags.contains(tag));
      }

      return matchesSearch && matchesType && matchesStatus && matchesWaterQuality && matchesAccessibility && matchesTags;
    }).toList();
    
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _filters.clear();
    _searchQuery = '';
    _filteredFountains = List.from(_fountains);
    notifyListeners();
  }

  // Search logic
  void searchFountains(String query) {
    _setSearchQuery(query);
    applyFilters();
  }

  // Filter logic
  void filterFountains(Map<String, dynamic> filters) {
    _setFilters(filters);
    applyFilters();
  }

  // Select fountain
  void selectFountain(PostgresFountain fountain) {
    _selectedFountain = fountain;
    notifyListeners();
  }

  // Get fountains in viewport with API calls
  Future<List<PostgresFountain>> getFountainsInViewport({
    required double northLat,
    required double southLat,
    required double eastLon,
    required double westLon,
    double? zoomLevel,
  }) async {
    try {
      // If connected to API, query for fountains in viewport
      if (_isConnected) {
        try {
          final requestBody = {
            'north': northLat,
            'south': southLat,
            'east': eastLon,
            'west': westLon,
            'zoom_level': (zoomLevel ?? 10).round(),
            'limit': 50
          };
          
          final response = await http.post(
            Uri.parse('$_apiBaseUrl/fountains/viewport'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          ).timeout(const Duration(seconds: 5));
          
          if (response.statusCode == 200) {
            final List<dynamic> jsonData = json.decode(response.body);
            final viewportFountains = jsonData.map((json) => PostgresFountain.fromMap(json)).toList();
            print('🗺️ API returned ${viewportFountains.length} fountains for viewport');
            return viewportFountains;
          } else {
            print('🗺️ API failed (${response.statusCode}), falling back to loaded fountains');
          }
        } catch (apiError) {
          print('🗺️ API error: $apiError, falling back to loaded fountains');
        }
      }
      
      // Wait for data to be loaded if it hasn't been yet
      if (_fountains.isEmpty) {
        if (_isConnected) {
          await _loadFountainsFromAPI();
        } else {
          await _loadMockFountains();
        }
      }
      
      // Return fountains in the viewport from loaded data
      final viewportFountains = _fountains.where((fountain) {
        return fountain.latitude >= southLat &&
               fountain.latitude <= northLat &&
               fountain.longitude >= westLon &&
               fountain.longitude <= eastLon;
      }).toList();
      
      print('🗺️ Fallback returned ${viewportFountains.length} fountains for viewport');
      return viewportFountains;
      
      return viewportFountains;
    } catch (e) {
      print('🗺️ Error in getFountainsInViewport: $e');
      _setError('Failed to get fountains in viewport: $e');
      return [];
    }
  }

  // Add fountain via API
  Future<bool> addFountain(PostgresFountain fountain) async {
    try {
      _setLoading(true);
      _clearError();

      if (_isConnected) {
        // Send to API
        final response = await http.post(
          Uri.parse('$_apiBaseUrl/fountains'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'name': fountain.name,
            'description': fountain.description,
            'location': {
              'latitude': fountain.latitude,
              'longitude': fountain.longitude,
            },
            'type': fountain.type.name,
            'status': fountain.status.name,
            'water_quality': fountain.waterQuality.name,
            'accessibility': fountain.accessibility.name,
            'tags': fountain.tags,
            'osm_data': fountain.osmData,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          // Refresh data from API
          await _loadFountainsFromAPI();
          return true;
        } else {
          throw Exception('API returned status ${response.statusCode}: ${response.body}');
        }
      } else {
        // For mock data, just add to the list
        _fountains.add(fountain);
        _filteredFountains.add(fountain);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _setError('Failed to add fountain: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update fountain via API
  Future<void> updateFountain(PostgresFountain fountain) async {
    try {
      _setLoading(true);
      _clearError();

      if (_isConnected) {
        // Send update to API
        final response = await http.put(
          Uri.parse('$_apiBaseUrl/fountains/${fountain.id}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'name': fountain.name,
            'description': fountain.description,
            'location': {
              'latitude': fountain.latitude,
              'longitude': fountain.longitude,
            },
            'type': fountain.type.name,
            'status': fountain.status.name,
            'water_quality': fountain.waterQuality.name,
            'accessibility': fountain.accessibility.name,
            'tags': fountain.tags,
            'osm_data': fountain.osmData,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          // Refresh data from API
          await _loadFountainsFromAPI();
        } else {
          throw Exception('API returned status ${response.statusCode}: ${response.body}');
        }
      } else {
        // For mock data, just update in the list
        final index = _fountains.indexWhere((f) => f.id == fountain.id);
        if (index != -1) {
          _fountains[index] = fountain;
          _filteredFountains[index] = fountain;
          notifyListeners();
        }
      }
    } catch (e) {
      _setError('Failed to update fountain: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Delete fountain via API
  Future<void> deleteFountain(String id) async {
    try {
      _setLoading(true);
      _clearError();

      if (_isConnected) {
        // Send delete to API
        final response = await http.delete(
          Uri.parse('$_apiBaseUrl/fountains/$id'),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          // Refresh data from API
          await _loadFountainsFromAPI();
        } else {
          throw Exception('API returned status ${response.statusCode}: ${response.body}');
        }
      } else {
        // For mock data, just remove from the list
        _fountains.removeWhere((f) => f.id == id);
        _filteredFountains.removeWhere((f) => f.id == id);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to delete fountain: $e');
    } finally {
      _setLoading(false);
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

  void _setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void _setFilters(Map<String, dynamic> filters) {
    _filters.clear();
    _filters.addAll(filters);
    notifyListeners();
  }

  void _setConnectionStatus(String status) {
    _connectionStatus = status;
    notifyListeners();
  }
}
