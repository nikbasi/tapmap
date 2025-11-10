# TapMap Flutter App

A Flutter application that displays fountains on an OpenStreetMap with optimized geohash-based clustering.

## Features

- **OpenStreetMap Integration**: Uses `flutter_map` to display OpenStreetMap tiles
- **Geohash-based Clustering**: Automatically aggregates fountains at low zoom levels
- **Smart Loading**: Shows cluster markers with counts when zoomed out, individual fountains when zoomed in
- **Optimized Performance**: Debounced API calls and efficient data loading

## Setup

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Configure Backend API

The app expects a backend API that connects to your PostgreSQL database. Update the API URL in `lib/services/fountain_api_service.dart`:

```dart
static const String baseUrl = 'http://your-backend-url:3000/api';
```

### 3. Backend API Requirements

Your backend needs to implement the following endpoint:

#### POST `/api/fountains/map-view`

**Request Body:**
```json
{
  "min_lat": 37.0,
  "max_lat": 38.0,
  "min_lng": -123.0,
  "max_lng": -122.0
}
```

**Response:**
```json
[
  {
    "result_type": "count",
    "geohash_prefix": "9q5hx",
    "fountain_count": 42,
    "center_lat": 37.7749,
    "center_lng": -122.4194
  },
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
]
```

The backend should call the PostgreSQL function `get_fountains_for_map_view()` which automatically determines whether to return counts or individual fountains based on the area size.

### 4. Example Backend Implementation (Node.js/Express)

```javascript
const express = require('express');
const { Pool } = require('pg');
const app = express();

app.use(express.json());

const pool = new Pool({
  // Your PostgreSQL connection config
  host: 'localhost',
  database: 'tapmap_db',
  user: 'tapmap_user',
  password: 'your_password',
  port: 5432,
});

app.post('/api/fountains/map-view', async (req, res) => {
  const { min_lat, max_lat, min_lng, max_lng } = req.body;
  
  try {
    const result = await pool.query(
      `SELECT * FROM get_fountains_for_map_view($1, $2, $3, $4, NULL)`,
      [min_lat, max_lat, min_lng, max_lng]
    );
    
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching fountains:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.listen(3000, () => {
  console.log('API server running on port 3000');
});
```

## How It Works

### Geohash Clustering

The app uses geohash-based clustering to optimize performance:

- **Low Zoom (0-10)**: Shows cluster markers with fountain counts grouped by geohash prefix
- **High Zoom (11+)**: Shows individual fountain markers at their exact locations

The backend's `get_fountains_for_map_view()` function automatically:
1. Calculates the visible area size
2. Determines appropriate geohash precision (2-8 characters)
3. Returns counts for large areas, individual fountains for small areas

### Map Events

The map listens for:
- `MapEventMoveEnd`: When the user finishes panning
- `MapEventScrollWheelZoomEnd`: When the user finishes zooming

API calls are debounced (500ms delay) to avoid excessive requests while the user is interacting with the map.

## Running the App

```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   ├── fountain.dart           # Fountain data model
│   ├── fountain_cluster.dart   # Cluster data model
│   └── map_result.dart         # Unified result model
├── services/
│   └── fountain_api_service.dart  # API service for backend calls
└── widgets/
    └── fountain_map.dart       # Main map widget with clustering
```

## Dependencies

- `flutter_map`: OpenStreetMap integration
- `latlong2`: Geographic coordinates
- `http`: HTTP client for API calls
- `provider`: State management (optional, for future use)

## Notes

- The app currently uses a placeholder API URL (`http://localhost:3000/api`)
- Make sure your backend is running and accessible before testing
- The map starts centered on San Francisco (37.7749, -122.4194) at zoom level 10
- Cluster markers show counts up to 999+ for very large clusters
