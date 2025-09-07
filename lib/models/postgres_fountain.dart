import 'package:latlong2/latlong.dart';
import 'package:water_fountain_finder/models/fountain.dart';

class PostgresFountain {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final FountainType type;
  final FountainStatus status;
  final WaterQuality waterQuality;
  final Accessibility accessibility;
  final String addedBy;
  final DateTime addedDate;
  final List<String> photos;
  final List<String> tags;
  final double? rating;
  final int reviewCount;
  final String? importSource;
  final DateTime? importDate;
  final Map<String, dynamic>? osmData;
  
  // Geohash fields for efficient geographic queries
  final String? geohash;
  final String? geohash_4;
  final String? geohash_3;
  final String? geohash_2;
  final String? geohash_1;

  PostgresFountain({
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
    this.photos = const [],
    this.tags = const [],
    this.rating,
    this.reviewCount = 0,
    this.importSource,
    this.importDate,
    this.osmData,
    this.geohash,
    this.geohash_4,
    this.geohash_3,
    this.geohash_2,
    this.geohash_1,
  });

  factory PostgresFountain.fromMap(Map<String, dynamic> map) {
    final dynamic location = map['location'];
    final double latitude = _asDouble(
          (location is Map ? location['latitude'] : null) ?? map['latitude']) ??
        0.0;
    final double longitude = _asDouble(
          (location is Map ? location['longitude'] : null) ?? map['longitude']) ??
        0.0;

    final String? addedDateRaw = (map['added_date'] ?? map['created_at']) as String?;
    final DateTime addedDate = _parseDateTime(addedDateRaw) ?? DateTime.now();

    return PostgresFountain(
      id: map['id']?.toString() ?? '',
      name: (map['name'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      latitude: latitude,
      longitude: longitude,
      type: _parseFountainType(map['type']?.toString()),
      status: _parseFountainStatus(map['status']?.toString()),
      waterQuality: _parseWaterQuality(map['water_quality']?.toString()),
      accessibility: _parseAccessibility(map['accessibility']?.toString()),
      addedBy: (map['added_by'] ?? '').toString(),
      addedDate: addedDate,
      photos: _asStringList(map['photos']),
      tags: _asStringList(map['tags']),
      rating: _asDouble(map['rating']),
      reviewCount: _asInt(map['review_count']) ?? 0,
      importSource: map['import_source']?.toString(),
      importDate: _parseDateTime(map['import_date']?.toString()),
      osmData: map['osm_data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(map['osm_data'])
          : null,
      geohash: map['geohash']?.toString(),
      geohash_4: map['geohash_4']?.toString(),
      geohash_3: map['geohash_3']?.toString(),
      geohash_2: map['geohash_2']?.toString(),
      geohash_1: map['geohash_1']?.toString(),
    );
  }

  // Factory method to create PostgresFountain from Fountain model
  factory PostgresFountain.fromFountain(dynamic fountain) {
    return PostgresFountain(
      id: fountain.id ?? '',
      name: fountain.name ?? '',
      description: fountain.description ?? '',
      latitude: fountain.latitude ?? 0.0,
      longitude: fountain.longitude ?? 0.0,
      type: fountain.type ?? FountainType.fountain,
      status: fountain.status ?? FountainStatus.active,
      waterQuality: fountain.waterQuality ?? WaterQuality.unknown,
      accessibility: fountain.accessibility ?? Accessibility.public,
      addedBy: fountain.addedBy ?? '',
      addedDate: fountain.addedDate ?? DateTime.now(),
      photos: fountain.photos ?? [],
      tags: fountain.tags ?? [],
      rating: fountain.rating,
      reviewCount: fountain.reviewCount ?? 0,
      importSource: fountain.importSource,
      importDate: fountain.importDate,
      osmData: fountain.osmData,
      geohash: fountain.geohash,
      geohash_4: fountain.geohash4,
      geohash_3: fountain.geohash3,
      geohash_2: fountain.geohash2,
      geohash_1: fountain.geohash1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'type': type.name,
      'status': status.name,
      'water_quality': waterQuality.name,
      'accessibility': accessibility.name,
      'added_by': addedBy,
      'added_date': addedDate.toIso8601String(),
      'photos': photos,
      'tags': tags,
      'rating': rating,
      'review_count': reviewCount,
      'import_source': importSource,
      'import_date': importDate?.toIso8601String(),
      'osm_data': osmData,
      'geohash': geohash,
      'geohash_4': geohash_4,
      'geohash_3': geohash_3,
      'geohash_2': geohash_2,
      'geohash_1': geohash_1,
    };
  }

  // Convert to LatLng for map usage
  LatLng get location => LatLng(latitude, longitude);

  // Helper methods
  bool get isActive => status == FountainStatus.active;
  bool get isPotable => waterQuality == WaterQuality.potable;
  bool get isPublic => accessibility == Accessibility.public;
  
  String get typeDisplayName {
    switch (type) {
      case FountainType.fountain:
        return 'Fountain';
      case FountainType.tap:
        return 'Tap';
      case FountainType.refillStation:
        return 'Refill Station';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case FountainStatus.active:
        return 'Active';
      case FountainStatus.inactive:
        return 'Inactive';
      case FountainStatus.maintenance:
        return 'Maintenance';
    }
  }

  String get waterQualityDisplayName {
    switch (waterQuality) {
      case WaterQuality.potable:
        return 'Potable';
      case WaterQuality.nonPotable:
        return 'Non-Potable';
      case WaterQuality.unknown:
        return 'Unknown';
    }
  }

  String get accessibilityDisplayName {
    switch (accessibility) {
      case Accessibility.public:
        return 'Public';
      case Accessibility.restricted:
        return 'Restricted';
      case Accessibility.private:
        return 'Private';
    }
  }
  
  // Import-related helper methods
  bool get isImported => importSource != null;
  bool get isOsmImported => importSource == 'italy_osm' || addedBy == 'osm_import_italy';
  
  String get displayName {
    if (isOsmImported && (name.isEmpty || name == 'Unnamed Fountain')) {
      return 'Italian ${typeDisplayName}';
    }
    return name;
  }
  
  String get importSourceDisplayName {
    if (importSource == 'italy_osm') return '🇮🇹 Italy (OSM)';
    if (addedBy == 'osm_import_italy') return '🇮🇹 Italy (OSM)';
    if (importSource != null) return '🌍 OpenStreetMap';
    return '📱 User Added';
  }
  
  bool get isRecentImport {
    if (importDate == null) return false;
    final daysSinceImport = DateTime.now().difference(importDate!).inDays;
    return daysSinceImport <= 30;
  }
  
  String get importStatusBadge {
    if (importDate == null) return 'Unknown';
    
    if (isRecentImport) {
      return '🆕 Recent';
    }
    
    final monthsSinceImport = DateTime.now().difference(importDate!).inDays ~/ 30;
    if (monthsSinceImport < 6) {
      return '✅ Current';
    } else {
      return '📅 Older';
    }
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed;
    }
    return null;
  }

  static DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  static List<String> _asStringList(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
    }
    // Handle comma-separated strings or JSON-encoded lists gracefully
    if (value is String) {
      if (value.trim().startsWith('[') && value.trim().endsWith(']')) {
        // Attempt to decode JSON array
        try {
          final dynamic decoded = value;
          if (decoded is List) {
            return decoded.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
          }
        } catch (_) {}
      }
      return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  static FountainType _parseFountainType(String? type) {
    switch (type) {
      case 'fountain':
        return FountainType.fountain;
      case 'tap':
        return FountainType.tap;
      case 'refillStation':
        return FountainType.refillStation;
      default:
        return FountainType.fountain;
    }
  }

  static FountainStatus _parseFountainStatus(String? status) {
    switch (status) {
      case 'active':
        return FountainStatus.active;
      case 'inactive':
        return FountainStatus.inactive;
      case 'maintenance':
        return FountainStatus.maintenance;
      default:
        return FountainStatus.active;
    }
  }

  static WaterQuality _parseWaterQuality(String? quality) {
    switch (quality) {
      case 'potable':
        return WaterQuality.potable;
      case 'nonPotable':
        return WaterQuality.nonPotable;
      case 'unknown':
        return WaterQuality.unknown;
      default:
        return WaterQuality.unknown;
    }
  }

  static Accessibility _parseAccessibility(String? accessibility) {
    switch (accessibility) {
      case 'public':
        return Accessibility.public;
      case 'restricted':
        return Accessibility.restricted;
      case 'private':
        return Accessibility.private;
      default:
        return Accessibility.public;
    }
  }

  // Convert to Fountain model for UI compatibility
  Fountain toFountain() {
    return Fountain(
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
      validations: [], // PostgresFountain doesn't have validations
      photos: photos,
      tags: tags,
      rating: rating,
      reviewCount: reviewCount,
      importSource: importSource,
      importDate: importDate,
      osmData: osmData,
      geohash: geohash,
      geohash4: geohash_4,
      geohash3: geohash_3,
    );
  }
}
