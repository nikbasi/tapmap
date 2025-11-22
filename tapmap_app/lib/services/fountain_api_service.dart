import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/map_result.dart';
import '../models/fountain.dart';
import '../models/fountain_cluster.dart';
import '../models/fountain_filters.dart';

class FountainApiService {
  static const String baseUrl = ApiConfig.baseUrl;
  
  /// Fetches fountains for the current map view
  /// The backend should call get_fountains_for_map_view() which automatically
  /// returns counts for low zoom and individual fountains for high zoom
  Future<List<MapResult>> getFountainsForMapView({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    FountainFilters? filters,
  }) async {
    try {
      final requestBody = {
        'min_lat': minLat,
        'max_lat': maxLat,
        'min_lng': minLng,
        'max_lng': maxLng,
        if (filters != null && filters.hasActiveFilters) ...filters.toJson(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/fountains/map-view'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<MapResult> results = [];
        for (final item in data) {
          results.add(MapResult.fromJson(item as Map<String, dynamic>));
        }
        return results;
      } else {
        throw Exception('Failed to load fountains: ${response.statusCode}');
      }
    } catch (e) {
      // For development, return empty list if API is not available
      print('Error fetching fountains: $e');
      return [];
    }
  }

  /// Alternative: Get fountain counts by area (for low zoom levels)
  Future<List<MapResult>> getFountainCounts({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    int geohashPrecision = 5,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fountains/counts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'min_lat': minLat,
          'max_lat': maxLat,
          'min_lng': minLng,
          'max_lng': maxLng,
          'geohash_precision': geohashPrecision,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<MapResult> results = [];
        for (final item in data) {
          results.add(MapResult.count(FountainCluster.fromJson(item as Map<String, dynamic>)));
        }
        return results;
      } else {
        throw Exception('Failed to load fountain counts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching fountain counts: $e');
      return [];
    }
  }

  /// Alternative: Get individual fountains in bounds (for high zoom levels)
  Future<List<MapResult>> getFountainsInBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fountains/bounds'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'min_lat': minLat,
          'max_lat': maxLat,
          'min_lng': minLng,
          'max_lng': maxLng,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<MapResult> results = [];
        for (final item in data) {
          results.add(MapResult.fountain(Fountain.fromJson(item as Map<String, dynamic>)));
        }
        return results;
      } else {
        throw Exception('Failed to load fountains: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching fountains in bounds: $e');
      return [];
    }
  }
}

