import 'package:latlong2/latlong.dart';

enum LocalFountainType { fountain, tap, refillStation }
enum LocalFountainStatus { active, inactive, maintenance }
enum LocalWaterQuality { potable, nonPotable, unknown }
enum LocalAccessibility { public, restricted, private }

class LocalFountain {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final LocalFountainType type;
  final LocalFountainStatus status;
  final LocalWaterQuality waterQuality;
  final LocalAccessibility accessibility;
  final String addedBy;
  final DateTime addedDate;
  final List<String> photos;
  final List<String> tags;
  final Map<String, dynamic>? osmData;
  
  // Geohash fields for efficient geographic queries
  final String geohashPrec5; // 5-character precision (~2.4km grid)
  final String geohashPrec4; // 4-character precision (~20km grid)
  final String geohashPrec3; // 3-character precision (~78km grid)

  LocalFountain({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.status,
    required this.waterQuality,
    required this.accessibility,
    required this.addedBy,
    required this.addedDate,
    required this.photos,
    required this.tags,
    this.osmData,
    required this.geohashPrec5,
    required this.geohashPrec4,
    required this.geohashPrec3,
  });

  // Convert to LatLng for map usage
  LatLng get location => LatLng(latitude, longitude);

  // Helper methods
  bool get isActive => status == LocalFountainStatus.active;
  bool get isPotable => waterQuality == LocalWaterQuality.potable;
  bool get isPublic => accessibility == LocalAccessibility.public;
  
  String get typeDisplayName {
    switch (type) {
      case LocalFountainType.fountain:
        return 'Fountain';
      case LocalFountainType.tap:
        return 'Tap';
      case LocalFountainType.refillStation:
        return 'Refill Station';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case LocalFountainStatus.active:
        return 'Active';
      case LocalFountainStatus.inactive:
        return 'Inactive';
      case LocalFountainStatus.maintenance:
        return 'Maintenance';
    }
  }

  String get waterQualityDisplayName {
    switch (waterQuality) {
      case LocalWaterQuality.potable:
        return 'Potable';
      case LocalWaterQuality.nonPotable:
        return 'Non-Potable';
      case LocalWaterQuality.unknown:
        return 'Unknown';
    }
  }

  String get accessibilityDisplayName {
    switch (accessibility) {
      case LocalAccessibility.public:
        return 'Public';
      case LocalAccessibility.restricted:
        return 'Restricted';
      case LocalAccessibility.private:
        return 'Private';
    }
  }

  // Import-related helper methods
  bool get isImported => addedBy == 'osm_import';
  bool get isOsmImported => addedBy == 'osm_import';
  
  String get displayName {
    if (isOsmImported && (name.isEmpty || name == 'Unnamed Fountain')) {
      return 'Italian ${typeDisplayName}';
    }
    return name;
  }
  
  String get importSourceDisplayName {
    if (isOsmImported) return '🇮🇹 Italy (OSM)';
    return '📱 User Added';
  }
  
  bool get isRecentImport {
    final daysSinceImport = DateTime.now().difference(addedDate).inDays;
    return daysSinceImport <= 30;
  }
  
  String get importStatusBadge {
    if (isRecentImport) {
      return '🆕 Recent';
    }
    
    final monthsSinceImport = DateTime.now().difference(addedDate).inDays ~/ 30;
    if (monthsSinceImport < 6) {
      return '✅ Current';
    } else {
      return '📅 Older';
    }
  }

  // Factory constructor from JSON
  factory LocalFountain.fromJson(String id, Map<String, dynamic> json) {
    // Handle both nested location and direct coordinates
    double latitude, longitude;
    
    if (json.containsKey('location') && json['location'] is Map<String, dynamic>) {
      final location = json['location'] as Map<String, dynamic>;
      latitude = (location['latitude'] as num).toDouble();
      longitude = (location['longitude'] as num).toDouble();
    } else {
      // Direct coordinates (fallback for test data)
      latitude = (json['latitude'] as num).toDouble();
      longitude = (json['longitude'] as num).toDouble();
    }
    
    return LocalFountain(
      id: json['id'] ?? id, // Use id from json if available, otherwise use parameter
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      latitude: latitude,
      longitude: longitude,
      type: _parseFountainType(json['type']),
      status: _parseFountainStatus(json['status']),
      waterQuality: _parseWaterQuality(json['waterQuality']),
      accessibility: _parseAccessibility(json['accessibility']),
      addedBy: json['addedBy'] ?? '',
      addedDate: DateTime.parse(json['addedDate']),
      photos: List<String>.from(json['photos'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      osmData: json['osmData'],
      // Geohash fields will be calculated after creation
      geohashPrec5: '',
      geohashPrec4: '',
      geohashPrec3: '',
    );
  }

  // Copy with method for updating geohash fields
  LocalFountain copyWithGeohashes({
    required String geohashPrec5,
    required String geohashPrec4,
    required String geohashPrec3,
  }) {
    return LocalFountain(
      id: id,
      name: name,
      description: description,
      latitude: latitude,
      longitude: longitude,
      type: type,
      status: status,
      waterQuality: waterQuality,
      accessibility: accessibility,
      addedBy: addedBy,
      addedDate: addedDate,
      photos: photos,
      tags: tags,
      osmData: osmData,
      geohashPrec5: geohashPrec5,
      geohashPrec4: geohashPrec4,
      geohashPrec3: geohashPrec3,
    );
  }

  static LocalFountainType _parseFountainType(String? type) {
    switch (type) {
      case 'fountain':
        return LocalFountainType.fountain;
      case 'tap':
        return LocalFountainType.tap;
      case 'refillStation':
        return LocalFountainType.refillStation;
      default:
        return LocalFountainType.fountain;
    }
  }

  static LocalFountainStatus _parseFountainStatus(String? status) {
    switch (status) {
      case 'active':
        return LocalFountainStatus.active;
      case 'inactive':
        return LocalFountainStatus.inactive;
      case 'maintenance':
        return LocalFountainStatus.maintenance;
      default:
        return LocalFountainStatus.active;
    }
  }

  static LocalWaterQuality _parseWaterQuality(String? quality) {
    switch (quality) {
      case 'potable':
        return LocalWaterQuality.potable;
      case 'nonPotable':
        return LocalWaterQuality.nonPotable;
      case 'unknown':
        return LocalWaterQuality.unknown;
      default:
        return LocalWaterQuality.unknown;
    }
  }

  static LocalAccessibility _parseAccessibility(String? accessibility) {
    switch (accessibility) {
      case 'public':
        return LocalAccessibility.public;
      case 'restricted':
        return LocalAccessibility.restricted;
      case 'private':
        return LocalAccessibility.private;
      default:
        return LocalAccessibility.public;
    }
  }
}
