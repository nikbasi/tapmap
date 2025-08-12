import 'package:cloud_firestore/cloud_firestore.dart';

enum FountainType { fountain, tap, refillStation }
enum FountainStatus { active, inactive, maintenance }
enum WaterQuality { potable, nonPotable, unknown }
enum Accessibility { public, restricted, private }

class Fountain {
  final String id;
  final String name;
  final String description;
  final GeoPoint location;
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

  Fountain({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
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
  });

  factory Fountain.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return Fountain(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? const GeoPoint(0, 0),
      type: _parseFountainType(data['type']),
      status: _parseFountainStatus(data['status']),
      waterQuality: _parseWaterQuality(data['waterQuality']),
      accessibility: _parseAccessibility(data['accessibility']),
      addedBy: data['addedBy'] ?? '',
      addedDate: (data['addedDate'] as Timestamp).toDate(),
      validations: _parseValidations(data['validations']),
      photos: List<String>.from(data['photos'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      rating: data['rating']?.toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'location': location,
      'type': type.name,
      'status': status.name,
      'waterQuality': waterQuality.name,
      'accessibility': accessibility.name,
      'addedBy': addedBy,
      'addedDate': Timestamp.fromDate(addedDate),
      'validations': validations.map((v) => v.toMap()).toList(),
      'photos': photos,
      'tags': tags,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  Fountain copyWith({
    String? id,
    String? name,
    String? description,
    GeoPoint? location,
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
  }) {
    return Fountain(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
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
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isValid: map['isValid'] ?? false,
      comment: map['comment'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'isValid': isValid,
      'comment': comment,
    };
  }
}
