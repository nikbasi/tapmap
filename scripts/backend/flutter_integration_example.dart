// Flutter Integration Example for Fountain Map Backend
// This example shows how to integrate with the geohash-based API

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class Fountain {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String type;
  final String status;
  final String waterQuality;
  final String accessibility;
  final List<String> tags;
  final String geohash;

  Fountain({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.status,
    required this.waterQuality,
    required this.accessibility,
    required this.tags,
    required this.geohash,
  });

  factory Fountain.fromJson(Map<String, dynamic> json) {
    return Fountain(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      latitude: json['location']['latitude'].toDouble(),
      longitude: json['location']['longitude'].toDouble(),
      type: json['type'],
      status: json['status'],
      waterQuality: json['water_quality'],
      accessibility: json['accessibility'],
      tags: List<String>.from(json['tags'] ?? []),
      geohash: json['geohash'],
    );
  }
}

class FountainApiService {
  static const String baseUrl = 'http://your-server.com'; // Replace with your server URL
  
  // Get fountains by geohash prefix (for specific zoom levels)
  static Future<List<Fountain>> getFountainsByGeohash(
    String geohashPrefix, {
    int limit = 1000,
    int offset = 0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fountains/geohash/$geohashPrefix?limit=$limit&offset=$offset'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Fountain.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load fountains: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching fountains: $e');
    }
  }

  // Get fountains by viewport (automatically selects optimal geohash precision)
  static Future<List<Fountain>> getFountainsByViewport({
    required double north,
    required double south,
    required double east,
    required double west,
    required int zoomLevel,
    int limit = 1000,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fountains/viewport'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'north': north,
          'south': south,
          'east': east,
          'west': west,
          'zoom_level': zoomLevel,
          'limit': limit,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Fountain.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load fountains: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching fountains: $e');
    }
  }

  // Search fountains by text
  static Future<List<Fountain>> searchFountains(
    String query, {
    int limit = 100,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fountains/search?query=${Uri.encodeComponent(query)}&limit=$limit'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Fountain.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search fountains: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching fountains: $e');
    }
  }

  // Add new fountain
  static Future<Fountain> addFountain({
    required String name,
    required String description,
    required double latitude,
    required double longitude,
    required String type,
    required String status,
    required String waterQuality,
    required String accessibility,
    required List<String> tags,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fountains'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'description': description,
          'location': {
            'latitude': latitude,
            'longitude': longitude,
          },
          'type': type,
          'status': status,
          'water_quality': waterQuality,
          'accessibility': accessibility,
          'tags': tags,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Fountain.fromJson(jsonData);
      } else {
        throw Exception('Failed to add fountain: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding fountain: $e');
    }
  }
}

// Example usage in a Flutter widget
class FountainMapWidget extends StatefulWidget {
  @override
  _FountainMapWidgetState createState() => _FountainMapWidgetState();
}

class _FountainMapWidgetState extends State<FountainMapWidget> {
  List<Fountain> fountains = [];
  bool isLoading = false;
  String? error;

  // Example: Load fountains for a specific area
  Future<void> loadFountainsForArea({
    required double north,
    required double south,
    required double east,
    required double west,
    required int zoomLevel,
  }) async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final newFountains = await FountainApiService.getFountainsByViewport(
        north: north,
        south: south,
        east: east,
        west: west,
        zoomLevel: zoomLevel,
        limit: 500, // Adjust based on zoom level
      );

      setState(() {
        fountains = newFountains;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  // Example: Load fountains by geohash (for specific zoom levels)
  Future<void> loadFountainsByGeohash(String geohashPrefix) async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final newFountains = await FountainApiService.getFountainsByGeohash(
        geohashPrefix,
        limit: 1000,
      );

      setState(() {
        fountains = newFountains;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Example controls
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              ElevatedButton(
                onPressed: () => loadFountainsForArea(
                  north: 40.8,
                  south: 40.7,
                  east: -74.0,
                  west: -74.1,
                  zoomLevel: 12,
                ),
                child: Text('Load NYC Area'),
              ),
              SizedBox(width: 16),
              ElevatedButton(
                onPressed: () => loadFountainsByGeohash('dr5'),
                child: Text('Load by Geohash (dr5)'),
              ),
            ],
          ),
        ),

        // Display fountains
        Expanded(
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : error != null
                  ? Center(child: Text('Error: $error'))
                  : ListView.builder(
                      itemCount: fountains.length,
                      itemBuilder: (context, index) {
                        final fountain = fountains[index];
                        return ListTile(
                          title: Text(fountain.name),
                          subtitle: Text('${fountain.latitude}, ${fountain.longitude}'),
                          trailing: Text(fountain.geohash),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// Example: Geohash utility functions for Flutter
class GeohashUtils {
  // Calculate optimal geohash precision based on zoom level
  static int getOptimalPrecision(int zoomLevel) {
    if (zoomLevel <= 3) return 1;
    if (zoomLevel <= 5) return 2;
    if (zoomLevel <= 7) return 3;
    if (zoomLevel <= 9) return 4;
    if (zoomLevel <= 11) return 5;
    if (zoomLevel <= 13) return 6;
    if (zoomLevel <= 15) return 7;
    if (zoomLevel <= 17) return 8;
    if (zoomLevel <= 19) return 9;
    return 10;
  }

  // Get geohash prefixes for a viewport at given precision
  static List<String> getGeohashPrefixesForViewport({
    required double north,
    required double south,
    required double east,
    required double west,
    required int precision,
  }) {
    // This is a simplified example - you'd need a proper geohash library
    // For production, use packages like 'geohash' or implement the logic
    
    // Placeholder implementation
    List<String> prefixes = [];
    
    // Calculate center point
    double centerLat = (north + south) / 2;
    double centerLon = (east + west) / 2;
    
    // Generate a sample geohash prefix (this is simplified)
    String baseGeohash = _generateSampleGeohash(centerLat, centerLon, precision);
    prefixes.add(baseGeohash);
    
    // Add neighboring prefixes for coverage
    // In a real implementation, you'd calculate actual neighboring geohashes
    
    return prefixes;
  }

  // Simplified geohash generation (replace with proper implementation)
  static String _generateSampleGeohash(double lat, double lon, int precision) {
    // This is a placeholder - use a proper geohash library
    String chars = '0123456789bcdefghjkmnpqrstuvwxyz';
    String result = '';
    
    for (int i = 0; i < precision; i++) {
      result += chars[(i * 7) % chars.length];
    }
    
    return result;
  }
}

// Example: Map viewport management
class MapViewport {
  final double north;
  final double south;
  final double east;
  final double west;
  final int zoomLevel;

  MapViewport({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
    required this.zoomLevel,
  });

  // Calculate optimal geohash precision for this viewport
  int get optimalGeohashPrecision => GeohashUtils.getOptimalPrecision(zoomLevel);

  // Get geohash prefixes that cover this viewport
  List<String> get geohashPrefixes => GeohashUtils.getGeohashPrefixesForViewport(
        north: north,
        south: south,
        east: east,
        west: west,
        precision: optimalGeohashPrecision,
      );

  // Check if a fountain is within this viewport
  bool containsFountain(Fountain fountain) {
    return fountain.latitude >= south &&
           fountain.latitude <= north &&
           fountain.longitude >= west &&
           fountain.longitude <= east;
  }
}

