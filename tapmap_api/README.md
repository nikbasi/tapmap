# TapMap API Server

Flask API server that connects to PostgreSQL and exposes fountain data endpoints for the Flutter app.

## Setup

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Configure Environment Variables

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` with your database credentials:

```env
DB_NAME=tapmap_db
DB_USER=postgres
DB_PASSWORD=your_password
DB_HOST=localhost
DB_PORT=5432

PORT=3000
FLASK_DEBUG=False
```

### 3. Run the Server

```bash
python app.py
```

Or with Flask directly:

```bash
flask run --host=0.0.0.0 --port=3000
```

The server will start on `http://localhost:3000`

## API Endpoints

### Health Check

```
GET /health
```

Returns server and database connection status.

### Get Fountains for Map View (Recommended)

```
POST /api/fountains/map-view
```

Automatically returns counts for low zoom or individual fountains for high zoom.

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

### Get Fountain Counts

```
POST /api/fountains/counts
```

Get fountain counts grouped by geohash prefix (for low zoom levels).

**Request Body:**
```json
{
  "min_lat": 37.0,
  "max_lat": 38.0,
  "min_lng": -123.0,
  "max_lng": -122.0,
  "geohash_precision": 5
}
```

### Get Fountains in Bounds

```
POST /api/fountains/bounds
```

Get individual fountains in bounds (for high zoom levels).

**Request Body:**
```json
{
  "min_lat": 37.0,
  "max_lat": 38.0,
  "min_lng": -123.0,
  "max_lng": -122.0,
  "max_results": 1000
}
```

### Get Fountain Details

```
GET /api/fountains/<fountain_id>
```

Get detailed information about a specific fountain.

## Database Functions Used

The API calls these PostgreSQL functions (defined in `tapmap_db/sql/query_helpers.sql`):

- `get_fountains_for_map_view()` - Smart function that auto-detects zoom level
- `get_fountain_counts_by_area()` - Returns counts grouped by geohash
- `get_fountains_in_bounds()` - Returns individual fountains
- `get_fountain_details()` - Returns detailed fountain information

## CORS

CORS is enabled to allow requests from the Flutter app running on different ports.

## Development

To run in debug mode, set `FLASK_DEBUG=True` in `.env` or run:

```bash
FLASK_DEBUG=True python app.py
```

