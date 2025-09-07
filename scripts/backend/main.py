#!/usr/bin/env python3
"""
FastAPI Backend for Fountain Map Application
Optimized for geohash-based queries and smooth zoom transitions
"""

import os
import json
import logging
from typing import List, Optional, Dict, Any
from datetime import datetime
import asyncio
from dotenv import load_dotenv

from fastapi import FastAPI, HTTPException, Query, Depends, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
import psycopg2
from psycopg2.extras import RealDictCursor
import geohash

# Load environment variables from .env file
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Database configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'database': os.getenv('DB_NAME', 'tapmap_db'),
    'user': os.getenv('DB_USER', 'tapmap_user'),
    'password': os.getenv('DB_PASSWORD', 'fountains.2025'),
    'port': os.getenv('DB_PORT', '5433')  # SSH tunnel port
}

# Initialize FastAPI app
app = FastAPI(
    title="Fountain Map API",
    description="Geohash-optimized API for fountain queries with smooth zoom transitions",
    version="1.0.0"
)

# CORS middleware for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:60199",  # Flutter Web port
        "http://127.0.0.1:60199",  # Alternative localhost
        "http://localhost:3000",   # Common dev port
        "http://127.0.0.1:3000",   # Alternative
        "*"  # Keep wildcard for now
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic models
class Location(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)

class FountainCreate(BaseModel):
    name: str
    description: Optional[str] = ""
    location: Location
    type: str = "fountain"
    status: str = "active"
    water_quality: str = "potable"
    accessibility: str = "public"
    tags: List[str] = []
    osm_data: Optional[Dict[str, Any]] = None

class FountainResponse(BaseModel):
    id: str
    name: str
    description: str
    location: Location
    type: str
    status: str
    water_quality: str
    accessibility: str
    added_by: str
    added_date: datetime
    validations: List[Dict[str, Any]]
    photos: List[Dict[str, Any]]
    tags: List[str]
    osm_data: Optional[Dict[str, Any]]
    geohash: str
    created_at: datetime
    updated_at: datetime

class GeohashQuery(BaseModel):
    geohash_prefix: str
    limit: int = 1000
    offset: int = 0

class ViewportQuery(BaseModel):
    north: float
    south: float
    east: float
    west: float
    zoom_level: int = Field(..., ge=1, le=20)
    limit: int = 100  # Reduced from 1000 to improve performance

# Database connection helper
def get_db_connection():
    """Get database connection with proper error handling"""
    try:
        logger.info(f"Attempting database connection with config: host={DB_CONFIG['host']}, port={DB_CONFIG['port']}, database={DB_CONFIG['database']}, user={DB_CONFIG['user']}")
        conn = psycopg2.connect(**DB_CONFIG)
        logger.info("Database connection successful")
        return conn
    except psycopg2.Error as e:
        logger.error(f"Database connection failed: {e}")
        logger.error(f"Connection details: {DB_CONFIG}")
        raise HTTPException(status_code=500, detail="Database connection failed")

# Geohash utilities
def calculate_optimal_precision(zoom_level: int) -> int:
    """
    Calculate optimal geohash precision based on zoom level.
    This ensures smooth transitions between zoom levels.
    """
    # Zoom level to geohash precision mapping
    # Lower zoom = lower precision (fewer results, faster queries)
    # Higher zoom = higher precision (more detailed results)
    if zoom_level <= 3:
        return 1
    elif zoom_level <= 5:
        return 2
    elif zoom_level <= 7:
        return 3
    elif zoom_level <= 9:
        return 4
    elif zoom_level <= 11:
        return 5
    elif zoom_level <= 13:
        return 6
    elif zoom_level <= 15:
        return 7
    elif zoom_level <= 17:
        return 8
    elif zoom_level <= 19:
        return 9
    else:
        return 10

def get_geohash_prefixes_for_viewport(north: float, south: float, east: float, west: float, precision: int) -> List[str]:
    """
    Get geohash prefixes that cover the viewport at given precision.
    Simplified to reduce complexity and improve performance.
    """
    prefixes = set()
    
    # Calculate geohashes for corners only (no neighbors for now)
    corners = [
        (north, west), (north, east),
        (south, west), (south, east)
    ]
    
    for lat, lon in corners:
        gh = geohash.encode(lat, lon, precision=precision)
        prefixes.add(gh)
    
    # Limit to maximum 16 prefixes to prevent performance issues
    prefix_list = list(prefixes)
    if len(prefix_list) > 16:
        prefix_list = prefix_list[:16]
    
    return prefix_list

# API Endpoints
@app.get("/")
async def root():
    """Health check endpoint"""
    return {"message": "Fountain Map API", "status": "healthy"}

@app.get("/health")
async def health_check():
    """Simple health check that doesn't require database access"""
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

@app.get("/test-flutter")
async def test_flutter_connection():
    """Test endpoint specifically for Flutter connectivity"""
    return {
        "message": "Flutter connection test successful!",
        "timestamp": datetime.now().isoformat(),
        "cors_origins": ["http://localhost:60199", "http://127.0.0.1:60199"],
        "status": "connected"
    }

@app.get("/test-fountain")
async def test_fountain_data():
    """Test endpoint that returns a single, clean fountain for Flutter parsing"""
    return {
        "id": "test_001",
        "name": "Test Fountain",
        "description": "A test fountain for debugging",
        "location": {
            "latitude": 40.7128,
            "longitude": -74.0060
        },
        "type": "fountain",
        "status": "active",
        "water_quality": "potable",
        "accessibility": "public",
        "added_by": "test_user",
        "added_date": "2024-01-01T00:00:00",
        "validations": [],
        "photos": [],
        "tags": ["test", "debug"],
        "osm_data": None,
        "geohash": "dr5ru",
        "created_at": "2024-01-01T00:00:00",
        "updated_at": "2024-01-01T00:00:00"
    }

@app.get("/debug-fountain")
async def debug_fountain_data():
    """Debug endpoint that returns raw database data to identify null fields"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        # Get just one fountain to inspect
        cursor.execute("SELECT * FROM fountains LIMIT 1")
        result = cursor.fetchone()
        
        cursor.close()
        conn.close()
        
        if result:
            # Convert to dict and show all fields
            raw_data = dict(result)
            logger.info(f"Raw fountain data: {raw_data}")
            
            # Check for null values in all fields
            null_fields = []
            for field, value in raw_data.items():
                if value is None:
                    null_fields.append(field)
            
            return {
                "raw_data": raw_data,
                "null_fields": null_fields,
                "message": "Raw database data for debugging"
            }
        else:
            return {"message": "No fountains found in database"}
            
    except Exception as e:
        logger.error(f"Error in debug endpoint: {e}")
        return {"error": str(e)}

@app.get("/test-serialization")
async def test_serialization():
    """Test endpoint to verify API can serialize fountain data properly"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        # Get one fountain and process it like the viewport endpoint
        cursor.execute("SELECT * FROM fountains LIMIT 1")
        result = cursor.fetchone()
        
        cursor.close()
        conn.close()
        
        if result:
            # Process the data exactly like the viewport endpoint
            fountain_data = dict(result)
            fountain_data['location'] = {
                'latitude': float(result['latitude']),
                'longitude': float(result['longitude'])
            }
            
            # Convert any Decimal fields to float
            for key, value in fountain_data.items():
                if hasattr(value, '__class__') and value.__class__.__name__ == 'Decimal':
                    fountain_data[key] = float(value)
            
            # Try to create the Pydantic model
            try:
                fountain = FountainResponse(**fountain_data)
                return {
                    "success": True,
                    "message": "Fountain data serialized successfully",
                    "fountain": fountain.dict(),
                    "types": {k: type(v).__name__ for k, v in fountain.dict().items()}
                }
            except Exception as parse_error:
                return {
                    "success": False,
                    "message": f"Failed to parse fountain: {parse_error}",
                    "raw_data": fountain_data,
                    "error": str(parse_error)
                }
        else:
            return {"message": "No fountains found in database"}
            
    except Exception as e:
        logger.error(f"Error in test serialization endpoint: {e}")
        return {"error": str(e)}

@app.get("/fountains")
async def get_all_fountains(
    limit: int = Query(1000, ge=1, le=10000),
    offset: int = Query(0, ge=0)
) -> List[FountainResponse]:
    """
    Get all fountains with pagination.
    """
    try:
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        query = """
        SELECT * FROM fountains 
        WHERE latitude IS NOT NULL AND longitude IS NOT NULL
        ORDER BY id
        LIMIT %s OFFSET %s
        """
        
        cursor.execute(query, (limit, offset))
        results = cursor.fetchall()
        
        # Convert to Pydantic models, filtering out null coordinates
        fountains = []
        for row in results:
            # Skip fountains with null coordinates
            if row['latitude'] is None or row['longitude'] is None:
                logger.warning(f"Skipping fountain {row.get('id', 'unknown')} with null coordinates")
                continue
                
            fountain_data = dict(row)
            fountain_data['location'] = {
                'latitude': float(row['latitude']),
                'longitude': float(row['longitude'])
            }
            fountains.append(FountainResponse(**fountain_data))
        
        cursor.close()
        conn.close()
        
        return fountains
        
    except Exception as e:
        logger.error(f"Error querying all fountains: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get("/fountains/geohash/{geohash_prefix}")
async def get_fountains_by_geohash(
    geohash_prefix: str,
    limit: int = Query(1000, ge=1, le=10000),
    offset: int = Query(0, ge=0)
) -> List[FountainResponse]:
    """
    Get fountains by geohash prefix.
    This is the core endpoint for efficient map queries.
    """
    try:
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        # Determine precision from geohash prefix length
        precision = len(geohash_prefix)
        if precision > 12:
            raise HTTPException(status_code=400, detail="Geohash prefix too long")
        
        # Build query based on precision
        precision_column = f"geohash_{precision}"
        
        query = f"""
        SELECT * FROM fountains 
        WHERE {precision_column} = %s 
        AND latitude IS NOT NULL AND longitude IS NOT NULL
        ORDER BY id
        LIMIT %s OFFSET %s
        """
        
        cursor.execute(query, (geohash_prefix, limit, offset))
        results = cursor.fetchall()
        
        # Convert to Pydantic models, filtering out null coordinates
        fountains = []
        for row in results:
            # Skip fountains with null coordinates
            if row['latitude'] is None or row['longitude'] is None:
                logger.warning(f"Skipping fountain {row.get('id', 'unknown')} with null coordinates")
                continue
                
            fountain_data = dict(row)
            fountain_data['location'] = {
                'latitude': float(row['latitude']),
                'longitude': float(row['longitude'])
            }
            fountains.append(FountainResponse(**fountain_data))
        
        cursor.close()
        conn.close()
        
        return fountains
        
    except Exception as e:
        logger.error(f"Error querying fountains by geohash: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.post("/fountains/viewport")
async def get_fountains_by_viewport(query: ViewportQuery) -> List[FountainResponse]:
    """
    Get fountains within a viewport using optimal geohash precision.
    This endpoint automatically selects the best precision for smooth zoom transitions.
    """
    try:
        start_time = datetime.now()
        logger.info(f"Viewport query started: zoom={query.zoom_level}, limit={query.limit}")
        
        # Calculate optimal precision for the zoom level
        precision = calculate_optimal_precision(query.zoom_level)
        logger.info(f"Calculated precision: {precision}")
        
        # Get geohash prefixes that cover the viewport
        geohash_prefixes = get_geohash_prefixes_for_viewport(
            query.north, query.south, query.east, query.west, precision
        )
        logger.info(f"Generated {len(geohash_prefixes)} geohash prefixes")
        
        if not geohash_prefixes:
            return []
        
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        # Build query for multiple geohash prefixes
        precision_column = f"geohash_{precision}"
        placeholders = ','.join(['%s'] * len(geohash_prefixes))
        
        query_sql = f"""
        SELECT * FROM fountains 
        WHERE {precision_column} IN ({placeholders})
        AND latitude IS NOT NULL AND longitude IS NOT NULL
        ORDER BY id
        LIMIT %s
        """
        
        logger.info(f"Executing database query with {len(geohash_prefixes)} prefixes")
        cursor.execute(query_sql, geohash_prefixes + [query.limit])
        results = cursor.fetchall()
        logger.info(f"Database query returned {len(results)} rows")
        
        # Convert to Pydantic models, filtering out null coordinates
        fountains = []
        for row in results:
            # Skip fountains with null coordinates
            if row['latitude'] is None or row['longitude'] is None:
                logger.warning(f"Skipping fountain {row.get('id', 'unknown')} with null coordinates")
                continue
            
            fountain_data = dict(row)
            
            # Ensure all numeric fields are properly converted
            fountain_data['location'] = {
                'latitude': float(row['latitude']),
                'longitude': float(row['longitude'])
            }
            
            # Convert any Decimal fields to float to prevent serialization issues
            for key, value in fountain_data.items():
                if hasattr(value, '__class__') and value.__class__.__name__ == 'Decimal':
                    fountain_data[key] = float(value)
            
            # Check for other null numeric fields that might cause issues
            numeric_fields = ['added_date', 'created_at', 'updated_at']
            for field in numeric_fields:
                if field in fountain_data and fountain_data[field] is None:
                    fountain_data[field] = datetime.now()
            
            try:
                fountain = FountainResponse(**fountain_data)
                fountains.append(fountain)
            except Exception as parse_error:
                logger.error(f"Failed to parse fountain {row.get('id', 'unknown')}: {parse_error}")
                logger.error(f"Fountain data: {fountain_data}")
                continue
        
        cursor.close()
        conn.close()
        
        elapsed = (datetime.now() - start_time).total_seconds()
        logger.info(f"Viewport query completed in {elapsed:.2f}s, returning {len(fountains)} fountains")
        
        return fountains
        
    except Exception as e:
        logger.error(f"Error querying fountains by viewport: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.post("/fountains")
async def create_fountain(fountain: FountainCreate) -> FountainResponse:
    """
    Create a new fountain with automatic geohash calculation.
    """
    try:
        # Calculate geohash from coordinates
        geohash_str = geohash.encode(
            fountain.location.latitude, 
            fountain.location.longitude, 
            precision=12
        )
        
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        # Calculate all precision levels
        precision_levels = []
        for i in range(1, 13):
            precision_levels.append(geohash_str[:i])
        
        # Insert fountain with all precision levels
        insert_query = """
        INSERT INTO fountains (
            id, name, description, latitude, longitude, type, status,
            water_quality, accessibility, tags, osm_data, geohash,
            geohash_1, geohash_2, geohash_3, geohash_4, geohash_5, geohash_6,
            geohash_7, geohash_8, geohash_9, geohash_10, geohash_11, geohash_12
        ) VALUES (
            %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
            %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
        ) RETURNING *
        """
        
        # Generate unique ID
        fountain_id = f"custom_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{hash(geohash_str) % 10000}"
        
        cursor.execute(insert_query, (
            fountain_id, fountain.name, fountain.description,
            fountain.location.latitude, fountain.location.longitude,
            fountain.type, fountain.status, fountain.water_quality,
            fountain.accessibility, json.dumps(fountain.tags),
            json.dumps(fountain.osm_data) if fountain.osm_data else None,
            geohash_str, *precision_levels
        ))
        
        result = cursor.fetchone()
        conn.commit()
        
        # Convert to response model
        fountain_data = dict(result)
        fountain_data['location'] = {
            'latitude': float(result['latitude']),
            'longitude': float(result['longitude'])
        }
        
        cursor.close()
        conn.close()
        
        return FountainResponse(**fountain_data)
        
    except Exception as e:
        logger.error(f"Error creating fountain: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get("/fountains/search")
async def search_fountains(
    query: str = Query(..., min_length=1),
    limit: int = Query(100, ge=1, le=1000)
) -> List[FountainResponse]:
    """
    Search fountains by name and description using full-text search.
    """
    try:
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        search_query = """
        SELECT * FROM fountains 
        WHERE to_tsvector('english', name || ' ' || COALESCE(description, '')) @@ plainto_tsquery('english', %s)
        AND latitude IS NOT NULL AND longitude IS NOT NULL
        ORDER BY ts_rank(to_tsvector('english', name || ' ' || COALESCE(description, '')), plainto_tsquery('english', %s)) DESC
        LIMIT %s
        """
        
        cursor.execute(search_query, (query, query, limit))
        results = cursor.fetchall()
        
        # Convert to Pydantic models, filtering out null coordinates
        fountains = []
        for row in results:
            # Skip fountains with null coordinates
            if row['latitude'] is None or row['longitude'] is None:
                logger.warning(f"Skipping fountain {row.get('id', 'unknown')} with null coordinates")
                continue
                
            fountain_data = dict(row)
            fountain_data['location'] = {
                'latitude': float(row['latitude']),
                'longitude': float(row['longitude'])
            }
            fountains.append(FountainResponse(**fountain_data))
        
        cursor.close()
        conn.close()
        
        return fountains
        
    except Exception as e:
        logger.error(f"Error searching fountains: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get("/stats")
async def get_database_stats():
    """
    Get database statistics including fountain counts by geohash precision.
    """
    try:
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        # Get total fountain count (only those with valid coordinates)
        cursor.execute("SELECT COUNT(*) as total FROM fountains WHERE latitude IS NOT NULL AND longitude IS NOT NULL")
        total_count = cursor.fetchone()['total']
        
        # Try to get precision stats, but don't fail if the view doesn't exist
        precision_stats = []
        try:
            cursor.execute("SELECT * FROM fountain_stats_by_precision")
            precision_stats = [dict(row) for row in cursor.fetchall()]
        except Exception as view_error:
            logger.warning(f"Could not access fountain_stats_by_precision view: {view_error}")
            # Return empty precision stats instead of failing
        
        cursor.close()
        conn.close()
        
        return {
            "total_fountains": total_count,
            "precision_stats": precision_stats,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Error getting stats: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)





