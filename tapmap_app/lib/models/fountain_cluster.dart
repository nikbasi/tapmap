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
    return FountainCluster(
      geohashPrefix: json['geohash_prefix'] ?? '',
      count: (json['fountain_count'] ?? json['count'] ?? 0).toInt(),
      centerLat: (json['center_lat'] ?? 0.0).toDouble(),
      centerLng: (json['center_lng'] ?? 0.0).toDouble(),
    );
  }
}

