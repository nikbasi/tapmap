# Flutter App Integration Guide

This guide explains how to integrate the TapMap database with your Flutter app for efficient map rendering at different zoom levels.

## Overview

The database provides functions that automatically return:
- **Counts** (grouped by area) for low zoom levels (world/country view)
- **Individual fountains** for high zoom levels (city/street view)

This prevents loading thousands of individual markers when viewing the entire world.

## Recommended Approach

### 1. Use `get_fountains_for_map_view()` - Auto-Detection

This function automatically determines whether to return counts or individual fountains based on the visible map area.

```dart
// In your Flutter app, when map bounds change:
Future<Map<String, dynamic>> getFountainsForMapView({
  required double minLat,
  required double maxLat,
  required double minLng,
  required double maxLng,
}) async {
  final response = await http.post(
    Uri.parse('$apiUrl/fountains/map-view'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'min_lat': minLat,
      'max_lat': maxLat,
      'min_lng': minLng,
      'max_lng': maxLng,
    }),
  );
  
  final data = jsonDecode(response.body);
  return data;
}
```

**Backend API endpoint example (Node.js/Express):**
```javascript
app.post('/fountains/map-view', async (req, res) => {
  const { min_lat, max_lat, min_lng, max_lng } = req.body;
  
  const result = await db.query(
    `SELECT * FROM get_fountains_for_map_view($1, $2, $3, $4, NULL)`,
    [min_lat, max_lat, min_lng, max_lng]
  );
  
  res.json(result.rows);
});
```

### 2. Handle Results in Flutter

The function returns a unified result set with a `result_type` field:

```dart
void handleMapData(List<dynamic> results) {
  for (var result in results) {
    if (result['result_type'] == 'count') {
      // Show count marker/cluster
      _addCountMarker(
        lat: result['center_lat'],
        lng: result['center_lng'],
        count: result['fountain_count'],
        geohashPrefix: result['geohash_prefix'],
      );
    } else if (result['result_type'] == 'fountain') {
      // Show individual fountain marker
      _addFountainMarker(
        id: result['fountain_id'],
        name: result['fountain_name'],
        lat: result['latitude'],
        lng: result['longitude'],
        waterQuality: result['water_quality'],
        accessibility: result['accessibility'],
      );
    }
  }
}
```

### 3. Alternative: Manual Control

If you want more control, use separate functions:

**For low zoom (counts only):**
```dart
Future<List<CountMarker>> getFountainCounts({
  required double minLat,
  required double maxLat,
  required double minLng,
  required double maxLng,
  int geohashPrecision = 5, // Adjust based on zoom level
}) async {
  // Call get_fountain_counts_by_area()
  // Returns: geohash_prefix, count, center_lat, center_lng
}
```

**For high zoom (individual fountains):**
```dart
Future<List<Fountain>> getFountainsInBounds({
  required double minLat,
  required double maxLat,
  required double minLng,
  required double maxLng,
}) async {
  // Call get_fountains_in_bounds()
  // Returns: id, name, latitude, longitude, geohash, etc.
}
```

## Zoom Level Strategy

### Recommended Precision by Zoom Level

| Zoom Level | Area Size | Geohash Precision | Function |
|------------|-----------|-------------------|----------|
| World (0-3) | > 1M km² | 2-3 chars | `get_fountain_counts_by_area()` |
| Country (4-5) | 100k-1M km² | 3-4 chars | `get_fountain_counts_by_area()` |
| Region (6-7) | 10k-100k km² | 4-5 chars | `get_fountain_counts_by_area()` |
| City (8-10) | 100-10k km² | 5-6 chars | `get_fountain_counts_by_area()` |
| District (11-13) | 10-100 km² | 6-7 chars | `get_fountains_in_bounds()` |
| Street (14+) | < 10 km² | 8-10 chars | `get_fountains_in_bounds()` |

### Implementation Example

```dart
void onMapBoundsChanged(LatLngBounds bounds) {
  final area = _calculateArea(bounds);
  
  if (area > 1000) {
    // Large area - show counts
    final precision = _getPrecisionForArea(area);
    _loadFountainCounts(bounds, precision);
  } else {
    // Small area - show individual fountains
    _loadIndividualFountains(bounds);
  }
}

int _getPrecisionForArea(double areaKm2) {
  if (areaKm2 > 1000000) return 2;
  if (areaKm2 > 100000) return 3;
  if (areaKm2 > 10000) return 4;
  if (areaKm2 > 1000) return 5;
  if (areaKm2 > 100) return 6;
  return 7;
}
```

## Performance Tips

1. **Cache results**: Cache count results for low zoom levels (they change less frequently)
2. **Debounce requests**: Wait for map movement to settle before querying
3. **Limit results**: The functions already have safety limits, but you can add more
4. **Use geohash for clustering**: The geohash prefix can be used for client-side clustering
5. **Index usage**: All queries use indexed columns (geohash, latitude, longitude)

## Example: Complete Flutter Widget

```dart
class FountainMap extends StatefulWidget {
  @override
  _FountainMapState createState() => _FountainMapState();
}

class _FountainMapState extends State<FountainMap> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }
  
  void _onCameraMove(CameraPosition position) {
    // Debounce this call
    _loadFountainsForVisibleArea();
  }
  
  Future<void> _loadFountainsForVisibleArea() async {
    if (_mapController == null) return;
    
    final bounds = await _mapController!.getVisibleRegion();
    
    final results = await api.getFountainsForMapView(
      minLat: bounds.southwest.latitude,
      maxLat: bounds.northeast.latitude,
      minLng: bounds.southwest.longitude,
      maxLng: bounds.northeast.longitude,
    );
    
    setState(() {
      _markers = results.map((result) {
        if (result['result_type'] == 'count') {
          return Marker(
            markerId: MarkerId('count_${result['geohash_prefix']}'),
            position: LatLng(
              result['center_lat'],
              result['center_lng'],
            ),
            icon: _createCountIcon(result['fountain_count']),
            infoWindow: InfoWindow(
              title: '${result['fountain_count']} fountains',
            ),
          );
        } else {
          return Marker(
            markerId: MarkerId(result['fountain_id']),
            position: LatLng(
              result['latitude'],
              result['longitude'],
            ),
            icon: _fountainIcon,
            infoWindow: InfoWindow(
              title: result['fountain_name'],
            ),
          );
        }
      }).toSet();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      onCameraMove: _onCameraMove,
      markers: _markers,
      initialCameraPosition: CameraPosition(
        target: LatLng(37.7749, -122.4194),
        zoom: 10,
      ),
    );
  }
}
```

## API Response Format

### Count Response (low zoom)
```json
{
  "result_type": "count",
  "geohash_prefix": "9q5hx",
  "fountain_count": 42,
  "center_lat": 37.7749,
  "center_lng": -122.4194
}
```

### Fountain Response (high zoom)
```json
{
  "result_type": "fountain",
  "fountain_id": "osm_node_12824958235",
  "fountain_name": "Unnamed Fountain",
  "latitude": 37.7749,
  "longitude": -122.4194,
  "geohash": "9q5hx12345",
  "status": "active",
  "water_quality": "potable",
  "accessibility": "public"
}
```

## Next Steps

1. Set up your backend API to call these database functions
2. Implement the Flutter map widget with zoom-based loading
3. Add caching for better performance
4. Test with different zoom levels to ensure smooth transitions


