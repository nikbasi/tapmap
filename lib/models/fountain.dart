enum FountainType { fountain, tap, refillStation }
enum FountainStatus { active, inactive, maintenance }
enum WaterQuality { potable, nonPotable, unknown }
enum Accessibility { public, restricted, private }

class Fountain {
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
  final List<Validation> validations;
  final List<String> photos;
  final List<String> tags;
  final double? rating;
  final int reviewCount;
  final String? importSource;
  final DateTime? importDate;
  final Map<String, dynamic>? osmData;
  // Geohash fields for efficient geographic queries
  final String? geohash;
  final String? geohash4;
  final String? geohash3;

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
    required this.addedBy,
    required this.addedDate,
    required this.validations,
    required this.photos,
    required this.tags,
    this.rating,
    this.reviewCount = 0,
    this.importSource,
    this.importDate,
    this.osmData,
    this.geohash,
    this.geohash4,
    this.geohash3,
  });

  factory Fountain.fromMap(Map<String, dynamic> data) {
    return Fountain(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      type: _parseFountainType(data['type']),
      status: _parseFountainStatus(data['status']),
      waterQuality: _parseWaterQuality(data['waterQuality']),
      accessibility: _parseAccessibility(data['accessibility']),
      addedBy: data['addedBy'] ?? '',
      addedDate: data['addedDate'] != null 
          ? DateTime.parse(data['addedDate']) 
          : DateTime.now(),
      validations: _parseValidations(data['validations']),
      photos: List<String>.from(data['photos'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      rating: data['rating']?.toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      importSource: data['importSource'],
      importDate: data['importDate'] != null 
          ? DateTime.parse(data['importDate']) 
          : null,
      osmData: data['osmData'],
      geohash: data['geohash'],
      geohash4: data['geohash4'],
      geohash3: data['geohash3'],
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
      'waterQuality': waterQuality.name,
      'accessibility': accessibility.name,
      'addedBy': addedBy,
      'addedDate': addedDate.toIso8601String(),
      'validations': validations.map((v) => v.toMap()).toList(),
      'photos': photos,
      'tags': tags,
      'rating': rating,
      'reviewCount': reviewCount,
      'importSource': importSource,
      'importDate': importDate?.toIso8601String(),
      'osmData': osmData,
      'geohash': geohash,
      'geohash4': geohash4,
      'geohash3': geohash3,
    };
  }

  Fountain copyWith({
    String? id,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    FountainType? type,
    FountainStatus? status,
    WaterQuality? waterQuality,
    Accessibility? accessibility,
    String? addedBy,
    DateTime? addedDate,
    List<Validation>? validations,
    List<String>? photos,
    List<String>? tags,
    double? rating,
    int? reviewCount,
    String? importSource,
    DateTime? importDate,
    Map<String, dynamic>? osmData,
    String? geohash,
    String? geohash4,
    String? geohash3,
  }) {
    return Fountain(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
      status: status ?? this.status,
      waterQuality: waterQuality ?? this.waterQuality,
      accessibility: accessibility ?? this.accessibility,
      addedBy: addedBy ?? this.addedBy,
      addedDate: addedDate ?? this.addedDate,
      validations: validations ?? this.validations,
      photos: photos ?? this.photos,
      tags: tags ?? this.tags,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      importSource: importSource ?? this.importSource,
      importDate: importDate ?? this.importDate,
      osmData: osmData ?? this.osmData,
      geohash: geohash ?? this.geohash,
      geohash4: geohash4 ?? this.geohash4,
      geohash3: geohash3 ?? this.geohash3,
    );
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

  static List<Validation> _parseValidations(List<dynamic>? validations) {
    if (validations == null) return [];
    return validations.map((v) => Validation.fromMap(v)).toList();
  }

  // Helper methods
  bool get isActive => status == FountainStatus.active;
  bool get isPotable => waterQuality == WaterQuality.potable;
  bool get isPublic => accessibility == Accessibility.public;
  bool get hasPhotos => photos.isNotEmpty;
  bool get hasTags => tags.isNotEmpty;
  bool get hasRating => rating != null;
  bool get hasValidations => validations.isNotEmpty;
  
  // Location helpers
  bool get hasValidLocation => latitude != 0.0 && longitude != 0.0;
  String get locationString => '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  
  // Rating helpers
  String get ratingDisplay => hasRating ? rating!.toStringAsFixed(1) : 'N/A';
  String get reviewCountDisplay => reviewCount > 0 ? '$reviewCount reviews' : 'No reviews';
  
  // Type helpers
  String get typeDisplay => type.name.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim();
  String get statusDisplay => status.name.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim();
  String get waterQualityDisplay => waterQuality.name.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim();
  String get accessibilityDisplay => accessibility.name.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim();

  // Display name methods for compatibility with existing UI
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

  @override
  String toString() {
    return 'Fountain(id: $id, name: $name, type: $type, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Fountain && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class Validation {
  final String userId;
  final DateTime timestamp;
  final bool isValid;
  final String? comment;

  Validation({
    required this.userId,
    required this.timestamp,
    required this.isValid,
    this.comment,
  });

  factory Validation.fromMap(Map<String, dynamic> map) {
    return Validation(
      userId: map['userId'] ?? '',
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp']) 
          : DateTime.now(),
      isValid: map['isValid'] ?? false,
      comment: map['comment'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'isValid': isValid,
      'comment': comment,
    };
  }
}
