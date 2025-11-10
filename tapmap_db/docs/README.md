# TapMap Database

Database setup for the TapMap Flutter app to find fountains on a map.

## Overview

This project provides:
- **PostgreSQL database schema** for both local development and production
- Data import script for fountain data
- Query helpers for common operations optimized for map-based queries

**Why PostgreSQL?**
- Free, open-source, and excellent for this use case
- Great spatial support with PostGIS (optional but powerful)
- Easy to set up on any cloud provider (AWS, Google Cloud, Azure, Oracle Cloud, etc.)
- Excellent performance for geospatial queries
- Same database for dev and production = no migration needed

## Project Structure

```
tapmap_db/
├── sql/                    # SQL schema and query functions
│   ├── schema.sql         # Database schema
│   └── query_helpers.sql  # Helper functions for queries
├── scripts/                # Utility scripts
│   ├── import_data.py    # Import fountain data from JSON
│   └── setup.sh          # Automated setup script
├── docs/                   # Documentation
│   ├── README.md         # This file
│   └── FLUTTER_INTEGRATION.md  # Flutter app integration guide
├── data/                   # Data files
│   └── world_fountains_combined.json
├── .env.example            # Environment variables template
├── .env                    # Your local environment variables (not in git)
└── requirements.txt       # Python dependencies
```

## Local Development Setup

### Prerequisites

- PostgreSQL 18 installed on your machine
- Python 3.7+ with pip

### Installation Steps

1. **Install PostgreSQL 18** (if not already installed):
   
   **macOS (using Postgres.app or similar):**
   - Download and install PostgreSQL 18 from [Postgres.app](https://postgresapp.com/) or [PostgreSQL.org](https://www.postgresql.org/download/macosx/)
   - Start PostgreSQL from the app (Postgres.app will start it automatically)
   - The default port is usually 5432
   - Add PostgreSQL to your PATH (Postgres.app usually does this automatically)
   
   **macOS (using Homebrew):**
   ```bash
   brew install postgresql@18
   brew services start postgresql@18
   ```
   
   **Ubuntu/Debian:**
   ```bash
   sudo apt-get install postgresql-18 postgresql-contrib
   sudo systemctl start postgresql
   ```

2. **Create database and user**:
   ```bash
   # Connect to PostgreSQL (default user is usually 'postgres' or your Mac username)
   psql postgres
   # Or if using Postgres.app, you might connect as your Mac user:
   # psql -d postgres
   
   # Create database and user
   CREATE DATABASE tapmap_db;
   CREATE USER tapmap_user WITH PASSWORD 'your_password';
   GRANT ALL PRIVILEGES ON DATABASE tapmap_db TO tapmap_user;
   \q
   ```
   
   **Note for Postgres.app users:**
   - The default superuser is usually your Mac username (not 'postgres')
   - You can check your username with: `whoami`
   - Connection string: `psql -d postgres` (no user specified uses your Mac user)

3. **Install Python dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Set up environment variables**:
   ```bash
   # Copy the example .env file
   cp .env.example .env
   
   # Edit .env with your database credentials
   # For Postgres.app users, DB_USER is usually your Mac username
   nano .env  # or use your preferred editor
   ```

5. **Create database schema**:
   ```bash
   psql -U tapmap_user -d tapmap_db -f sql/schema.sql
   ```

6. **Load query helper functions**:
   ```bash
   psql -U tapmap_user -d tapmap_db -f sql/query_helpers.sql
   ```

7. **Import fountain data**:
   
   **Using .env file (recommended):**
   ```bash
   python scripts/import_data.py --json data/world_fountains_combined.json
   ```
   
   **Or override with command line arguments:**
   ```bash
   python scripts/import_data.py \
     --json data/world_fountains_combined.json \
     --dbname tapmap_db \
     --user tapmap_user \
     --password your_password \
     --host localhost
   ```

   **Or use the automated setup script:**
   ```bash
   ./scripts/setup.sh
   ```

## Database Schema

### Main Tables

- **fountains**: Main table storing fountain information
  - Location (latitude, longitude, geohash)
  - Status, water quality, accessibility
  - Metadata (added by, dates)

- **fountain_tags**: Tags associated with each fountain (many-to-many)

- **fountain_osm_data**: OpenStreetMap data for imported fountains

- **fountain_validations**: User validations/verifications

- **fountain_photos**: Photo references for fountains

### Indexes

- **Geohash index**: Fast proximity searches using geohash prefix matching
- Spatial indexes on latitude/longitude for fast location queries
- Indexes on status, accessibility for filtering
- Indexes on tags for tag-based searches

### Geohash

The database includes a `geohash` column that is automatically computed during import. Geohash provides:
- **Fast proximity searches**: Use geohash prefix matching to quickly find nearby fountains
- **Efficient indexing**: B-tree index on geohash enables very fast lookups
- **Precision**: 10-character geohash (≈ 0.6m precision) is stored, suitable for fountain locations
- **Flexible queries**: Use prefix matching to query at any zoom level (world view to individual fountains)

Geohash precision reference:
- 2 chars ≈ 1,250km per cell (continent level)
- 3 chars ≈ 156km per cell (country level)
- 4 chars ≈ 39km per cell (state/region level)
- 5 chars ≈ 4.9km per cell (city level)
- 6 chars ≈ 1.2km per cell (district level)
- 7 chars ≈ 153m per cell (neighborhood level)
- 8 chars ≈ 19m per cell (street level)
- 9 chars ≈ 2.4m per cell (building level)
- 10 chars ≈ 0.6m per cell (stored precision - individual fountain level)

## Common Queries

### Find fountains near a location

**For Flutter map with zoom levels (recommended):**
```sql
-- Smart function: automatically returns counts (low zoom) or individual fountains (high zoom)
SELECT * FROM get_fountains_for_map_view(
    min_lat => 37.0, 
    max_lat => 38.0, 
    min_lng => -123.0, 
    max_lng => -122.0,
    return_counts => NULL  -- NULL = auto-detect based on area size
);

-- Get counts grouped by area (for low zoom levels)
SELECT * FROM get_fountain_counts_by_area(
    min_lat => 37.0,
    max_lat => 38.0,
    min_lng => -123.0,
    max_lng => -122.0,
    geohash_precision => 5  -- Adjust based on zoom: 2-3 world, 4-5 country, 6-7 city
);

-- Get individual fountains in bounds (for high zoom levels)
SELECT * FROM get_fountains_in_bounds(
    min_lat => 37.7,
    max_lat => 37.8,
    min_lng => -122.5,
    max_lng => -122.4,
    max_results => 1000
);
```

**Using geohash for proximity (alternative):**
```sql
-- Use the helper function with geohash optimization
SELECT * FROM find_fountains_nearby_geohash(37.7749, -122.4194, 5.0, 50);

-- Or find by geohash prefix (very fast for map tiles)
SELECT * FROM find_fountains_by_geohash_prefix('9q5', 50);
```

**Using Haversine formula (traditional method):**
```sql
-- Find fountains within 5km of a point (using bounding box approximation)
SELECT 
    id, name, latitude, longitude,
    (
        6371 * acos(
            cos(radians(37.7749)) * cos(radians(latitude)) *
            cos(radians(longitude) - radians(-122.4194)) +
            sin(radians(37.7749)) * sin(radians(latitude))
        )
    ) AS distance_km
FROM fountains
WHERE 
    latitude BETWEEN 37.7749 - (5.0 / 111.0) AND 37.7749 + (5.0 / 111.0)
    AND longitude BETWEEN -122.4194 - (5.0 / (111.0 * cos(radians(37.7749)))) 
                      AND -122.4194 + (5.0 / (111.0 * cos(radians(37.7749))))
    AND status = 'active'
ORDER BY distance_km
LIMIT 50;
```

### Find fountains by tag

```sql
SELECT f.*
FROM fountains f
JOIN fountain_tags ft ON f.id = ft.fountain_id
WHERE ft.tag = 'amenity:drinking_water'
  AND f.status = 'active';
```

### Get fountain with all related data

```sql
SELECT 
    f.*,
    array_agg(DISTINCT ft.tag) as tags,
    osd.osm_id,
    osd.source
FROM fountains f
LEFT JOIN fountain_tags ft ON f.id = ft.fountain_id
LEFT JOIN fountain_osm_data osd ON f.id = osd.fountain_id
WHERE f.id = 'osm_node_12824958235'
GROUP BY f.id, osd.osm_id, osd.source;
```

## Deployment to Production

### Setting up PostgreSQL on Cloud Server (Ubuntu)

You can deploy PostgreSQL directly on any Ubuntu cloud instance (AWS, Google Cloud, Azure, Oracle Cloud, etc.):

1. **SSH into your cloud Ubuntu instance**

2. **Install PostgreSQL 18**:
   ```bash
   sudo apt update
   sudo apt install postgresql-18 postgresql-contrib
   sudo systemctl start postgresql
   sudo systemctl enable postgresql
   ```

3. **Configure PostgreSQL**:
   ```bash
   # Edit postgresql.conf for production settings
   # Location depends on installation:
   # - Postgres.app: ~/Library/Application Support/Postgres/var-18/postgresql.conf
   # - Homebrew: /opt/homebrew/var/postgresql@18/postgresql.conf
   # - Ubuntu: /etc/postgresql/18/main/postgresql.conf
   # Adjust: shared_buffers, effective_cache_size, etc.
   
   # Edit pg_hba.conf for remote connections (if needed)
   # Same locations as above, but pg_hba.conf
   ```

4. **Create production database**:
   ```bash
   sudo -u postgres psql
   CREATE DATABASE tapmap_db;
   CREATE USER tapmap_user WITH PASSWORD 'secure_password';
   GRANT ALL PRIVILEGES ON DATABASE tapmap_db TO tapmap_user;
   \q
   ```

5. **Transfer schema and data from local to cloud**:
   ```bash
   # From your local machine
   pg_dump -U tapmap_user -d tapmap_db -h localhost > tapmap_backup.sql
   
   # Copy to cloud server
   scp tapmap_backup.sql user@your-cloud-server-ip:/tmp/
   
   # On cloud server, restore
   psql -U tapmap_user -d tapmap_db -f /tmp/tapmap_backup.sql
   ```

6. **Set up firewall** (if accessing remotely):
   ```bash
   sudo ufw allow 5432/tcp
   ```

## Flutter App Integration

See [FLUTTER_INTEGRATION.md](FLUTTER_INTEGRATION.md) for detailed Flutter integration guide.

### Connection String Examples

**PostgreSQL (local development)**:
```
postgresql://tapmap_user:password@localhost:5432/tapmap_db
```

**PostgreSQL (production)**:
```
postgresql://tapmap_user:password@your-cloud-server-ip:5432/tapmap_db
```

### Recommended Flutter Packages

- **Database**: `sqflite` (for local caching) + HTTP client for API calls
- **HTTP Client**: `http` or `dio` for REST API calls
- **Location**: `geolocator` for getting user location
- **Maps**: `google_maps_flutter` or `mapbox_maps_flutter`

### Backend API Recommendation

Create a REST API (using Node.js/Express, Python/Flask, or similar) that:
- Connects to your PostgreSQL database
- Calls the database functions (`get_fountains_for_map_view`, etc.)
- Returns JSON responses to your Flutter app
- Handles authentication, rate limiting, etc.

This keeps your database credentials secure and provides a clean API for your Flutter app.

### Suggested API Endpoints

- `POST /api/fountains/map-view` - Get fountains for map view (counts or individual)
- `GET /api/fountains/{id}` - Get fountain details
- `POST /api/fountains` - Add new fountain
- `PUT /api/fountains/{id}` - Update fountain
- `GET /api/fountains/search?q={query}` - Search fountains

## Development Tips

1. **Use connection pooling** for production
2. **Implement caching** in your Flutter app to reduce API calls
3. **Add pagination** for location queries to limit result sets
4. **Monitor query performance** and optimize indexes as needed
5. **Backup regularly** before major changes

## Troubleshooting

### Import fails with memory error
- Reduce batch size: `--batch-size 500`
- Process in chunks if file is very large

### Connection refused
- Check PostgreSQL is running: `brew services list` (macOS) or `sudo systemctl status postgresql` (Linux)
- Verify connection settings in import script

### Permission denied
- Ensure database user has proper privileges
- Check PostgreSQL `pg_hba.conf` for authentication settings

## License

[Add your license here]
