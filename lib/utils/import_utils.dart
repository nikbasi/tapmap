import 'package:cloud_firestore/cloud_firestore.dart';

class ImportUtils {
  /// Collection name for imported fountains
  static const String fountainsCollection = 'fountains';
  
  /// Source identifier for Italian OSM imports
  static const String italyOsmSource = 'italy_osm';
  
  /// Source identifier for OSM imports
  static const String osmImportSource = 'osm_import_italy';
  
  /// Get all imported Italian fountains
  static Stream<QuerySnapshot> getItalianFountainsStream() {
    return FirebaseFirestore.instance
        .collection(fountainsCollection)
        .where('importSource', isEqualTo: italyOsmSource)
        .snapshots();
  }
  
  /// Get imported Italian fountains with pagination
  static Query<Map<String, dynamic>> getItalianFountainsQuery({
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) {
    Query query = FirebaseFirestore.instance
        .collection(fountainsCollection)
        .where('importSource', isEqualTo: italyOsmSource)
        .orderBy('addedDate', descending: true)
        .limit(limit);
    
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    
    return query;
  }
  
  /// Get imported fountains by region (approximate)
  static Query<Map<String, dynamic>> getItalianFountainsByRegion({
    required String region,
    int limit = 50,
  }) {
    // Define approximate latitude ranges for Italian regions
    final regionBounds = _getRegionBounds(region);
    
    return FirebaseFirestore.instance
        .collection(fountainsCollection)
        .where('importSource', isEqualTo: italyOsmSource)
        .where('location.latitude', isGreaterThanOrEqualTo: regionBounds['minLat'])
        .where('location.latitude', isLessThanOrEqualTo: regionBounds['maxLat'])
        .limit(limit);
  }
  
  /// Get fountain statistics for imported data
  static Future<Map<String, dynamic>> getImportStatistics() async {
    try {
      final italyFountains = await FirebaseFirestore.instance
          .collection(fountainsCollection)
          .where('importSource', isEqualTo: italyOsmSource)
          .get();
      
      final totalCount = italyFountains.docs.length;
      
      // Count by type
      final typeCounts = <String, int>{};
      final regionCounts = <String, int>{};
      
      for (final doc in italyFountains.docs) {
        final data = doc.data();
        
        // Count by type
        final type = data['type'] ?? 'unknown';
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
        
        // Count by region (approximate)
        final lat = data['location']?['latitude'] ?? 0.0;
        final region = _getRegionFromLatitude(lat);
        regionCounts[region] = (regionCounts[region] ?? 0) + 1;
      }
      
      return {
        'totalFountains': totalCount,
        'typeDistribution': typeCounts,
        'regionDistribution': regionCounts,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'totalFountains': 0,
        'typeDistribution': {},
        'regionDistribution': {},
      };
    }
  }
  
  /// Check if a fountain is imported from OSM
  static bool isImportedFountain(Map<String, dynamic> fountainData) {
    return fountainData['importSource'] == italyOsmSource ||
           fountainData['addedBy'] == osmImportSource;
  }
  
  /// Get display name for imported fountain
  static String getImportedFountainDisplayName(Map<String, dynamic> fountainData) {
    final name = fountainData['name'] ?? 'Unnamed Fountain';
    final type = fountainData['type'] ?? 'unknown';
    
    if (name == 'Unnamed Fountain') {
      return 'Italian ${type.replaceAll('_', ' ')}';
    }
    
    return name;
  }
  
  /// Get region bounds for Italian regions
  static Map<String, double> _getRegionBounds(String region) {
    switch (region.toLowerCase()) {
      case 'northern':
        return {'minLat': 44.0, 'maxLat': 47.1};
      case 'central':
        return {'minLat': 41.0, 'maxLat': 44.0};
      case 'southern':
        return {'minLat': 35.5, 'maxLat': 41.0};
      case 'sicily':
        return {'minLat': 35.5, 'maxLat': 38.5};
      case 'sardinia':
        return {'minLat': 38.5, 'maxLat': 41.0};
      default:
        return {'minLat': 35.5, 'maxLat': 47.1}; // All of Italy
    }
  }
  
  /// Get region name from latitude
  static String _getRegionFromLatitude(double latitude) {
    if (latitude >= 44.0) return 'Northern Italy';
    if (latitude >= 41.0) return 'Central Italy';
    if (latitude >= 38.5) return 'Sardinia';
    if (latitude >= 35.5) return 'Sicily';
    return 'Southern Italy';
  }
  
  /// Get import source display name
  static String getImportSourceDisplayName(String? importSource) {
    switch (importSource) {
      case italyOsmSource:
        return '🇮🇹 Italy (OSM)';
      case 'osm_import':
        return '🌍 OpenStreetMap';
      default:
        return '📱 User Added';
    }
  }
  
  /// Check if import is recent (within last 30 days)
  static bool isRecentImport(DateTime? importDate) {
    if (importDate == null) return false;
    final daysSinceImport = DateTime.now().difference(importDate).inDays;
    return daysSinceImport <= 30;
  }
  
  /// Get import status badge text
  static String getImportStatusBadge(DateTime? importDate) {
    if (importDate == null) return 'Unknown';
    
    if (isRecentImport(importDate)) {
      return '🆕 Recent';
    }
    
    final monthsSinceImport = DateTime.now().difference(importDate).inDays ~/ 30;
    if (monthsSinceImport < 6) {
      return '✅ Current';
    } else {
      return '📅 Older';
    }
  }
}


