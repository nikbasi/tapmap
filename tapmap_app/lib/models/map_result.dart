import 'fountain.dart';
import 'fountain_cluster.dart';

enum MapResultType { count, fountain }

class MapResult {
  final MapResultType type;
  final FountainCluster? cluster;
  final Fountain? fountain;

  MapResult.count(FountainCluster cluster)
      : type = MapResultType.count,
        cluster = cluster,
        fountain = null;

  MapResult.fountain(Fountain fountain)
      : type = MapResultType.fountain,
        cluster = null,
        fountain = fountain;

  factory MapResult.fromJson(Map<String, dynamic> json) {
    final resultType = json['result_type'] as String?;
    
    if (resultType == 'count') {
      return MapResult.count(FountainCluster.fromJson(json));
    } else {
      return MapResult.fountain(Fountain.fromJson(json));
    }
  }
}

