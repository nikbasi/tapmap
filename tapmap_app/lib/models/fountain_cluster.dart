class FountainCluster {
  final String geohashPrefix;
  final int count;
  final double centerLat;
  final double centerLng;

  FountainCluster({
    required this.geohashPrefix,
    required this.count,
    required this.centerLat,
    required this.centerLng,
  });

  factory FountainCluster.fromJson(Map<String, dynamic> json) {
    // Handle both string and numeric values from database
    final centerLat = json['center_lat'];
    final centerLng = json['center_lng'];
    
    return FountainCluster(
      geohashPrefix: json['geohash_prefix'] ?? '',
      count: (json['fountain_count'] ?? json['count'] ?? 0).toInt(),
      centerLat: centerLat is String ? double.parse(centerLat) : (centerLat ?? 0.0).toDouble(),
      centerLng: centerLng is String ? double.parse(centerLng) : (centerLng ?? 0.0).toDouble(),
    );
  }
}

