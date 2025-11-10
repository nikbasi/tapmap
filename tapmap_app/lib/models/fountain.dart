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
    return Fountain(
      id: json['fountain_id'] ?? json['id'] ?? '',
      name: json['fountain_name'] ?? json['name'] ?? 'Unnamed Fountain',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      geohash: json['geohash'],
      status: json['status'],
      waterQuality: json['water_quality'],
      accessibility: json['accessibility'],
    );
  }
}

