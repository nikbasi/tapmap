class Fountain {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? geohash;
  final String? status;
  final String? waterQuality;
  final String? accessibility;

  Fountain({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.geohash,
    this.status,
    this.waterQuality,
    this.accessibility,
  });

  factory Fountain.fromJson(Map<String, dynamic> json) {
    // Handle both string and numeric values from database
    final latitude = json['latitude'];
    final longitude = json['longitude'];
    
    return Fountain(
      id: json['fountain_id'] ?? json['id'] ?? '',
      name: json['fountain_name'] ?? json['name'] ?? 'Unnamed Fountain',
      latitude: latitude is String ? double.parse(latitude) : (latitude ?? 0.0).toDouble(),
      longitude: longitude is String ? double.parse(longitude) : (longitude ?? 0.0).toDouble(),
      geohash: json['geohash'],
      status: json['status'],
      waterQuality: json['water_quality'],
      accessibility: json['accessibility'],
    );
  }
}

