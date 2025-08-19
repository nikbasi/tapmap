import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:dart_geohash/dart_geohash.dart';

class GeohashUtils {
	static final GeoHasher _hasher = GeoHasher();

	// Encode latitude/longitude to geohash with given precision
	static String encode(double latitude, double longitude, {int precision = 5}) {
		final clamped = precision.clamp(1, 12);
		return _hasher.encode(latitude, longitude, precision: clamped);
	}

	static String encodeLatLng(LatLng point, {int precision = 5}) {
		return encode(point.latitude, point.longitude, precision: precision);
	}

	// Choose precision by zoom; clamp to 3..5 because our DB has geohash3/geohash4/geohash (5)
	static int getOptimalPrecision(double zoomLevel) {
		if (zoomLevel >= 15) return 5; // ~4.9 km cells
		if (zoomLevel >= 12) return 4; // ~39 km cells
		return 3; // ~156 km cells
	}

	// Neighbors of a geohash (8 adjacent cells)
	static List<String> getNeighbors(String geohash) {
		if (geohash.isEmpty) return [];
		final neighborsMap = _hasher.neighbors(geohash);
		return neighborsMap.values.toList();
	}

	// Approx cell size in degrees at equator for given precision
	// Values derived from standard geohash cell sizes
	static Map<String, double> _cellSizeDeg(int precision) {
		switch (precision) {
			case 5:
				return {'lat': 0.0439, 'lonEquator': 0.0439}; // ~4.89 km
			case 4:
				return {'lat': 0.3516, 'lonEquator': 0.3516}; // ~39.1 km
			default: // 3
				return {'lat': 1.4063, 'lonEquator': 1.4063}; // ~156 km
		}
	}

	// Generate a minimal set of geohash prefixes (precision 3-5) to cover a viewport
	static List<String> getViewportGeohashes({
		required double northLat,
		required double southLat,
		required double eastLon,
		required double westLon,
		int precision = 4,
	}) {
		final p = precision.clamp(3, 5);
		final centerLat = (northLat + southLat) / 2.0;
		final size = _cellSizeDeg(p);
		final latStep = max(size['lat']! / 2.0, 0.0005);
		final lonEquator = size['lonEquator']!;
		final cosLat = cos(centerLat * pi / 180.0);
		final lonStep = max((cosLat == 0 ? lonEquator : lonEquator / max(cosLat, 0.01)) / 2.0, 0.0005);

		final Set<String> hashes = {};
		for (double lat = southLat; lat <= northLat; lat += latStep) {
			for (double lon = westLon; lon <= eastLon; lon += lonStep) {
				final h = encode(lat, lon, precision: p);
				hashes.add(h);
			}
		}

		// Also include neighbors of center cell to avoid edge holes
		final centerHash = encode(centerLat, (eastLon + westLon) / 2.0, precision: p);
		hashes.add(centerHash);
		hashes.addAll(getNeighbors(centerHash));

		return hashes.toList();
	}
}
