#!/usr/bin/env python3
"""
Import fountain data from JSON file into PostgreSQL database.
"""

import json
import sys
import os
import psycopg2
from psycopg2.extras import execute_batch
from datetime import datetime
import argparse
from typing import Dict, Any, List
import geohash2
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

def parse_date(date_str: str) -> datetime:
    """Parse ISO format date string."""
    if not date_str:
        return None
    try:
        return datetime.fromisoformat(date_str.replace('Z', '+00:00'))
    except:
        return None

def import_fountains(conn, json_file_path: str, batch_size: int = 1000):
    """
    Import fountain data from JSON file into database.
    
    Args:
        conn: PostgreSQL database connection
        json_file_path: Path to JSON file
        batch_size: Number of records to insert per batch
    """
    cursor = conn.cursor()
    
    print(f"Reading JSON file: {json_file_path}")
    
    # Read and parse JSON file
    try:
        with open(json_file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error reading JSON file: {e}")
        sys.exit(1)
    
    print(f"Found {len(data)} fountains to import")
    
    # Prepare data for batch insertion
    fountains = []
    tags_data = []
    osm_data = []
    validations_data = []
    photos_data = []
    
    for fountain_id, fountain in data.items():
        location = fountain.get('location', {})
        lat = float(location.get('latitude', 0))
        lng = float(location.get('longitude', 0))
        
        # Compute geohash (precision 10 ≈ 0.6m, excellent for fountain locations)
        # Precision reference: 7 chars ≈ 153m, 8 chars ≈ 19m, 9 chars ≈ 2.4m, 10 chars ≈ 0.6m
        geohash = None
        if lat != 0 or lng != 0:  # Only compute if we have valid coordinates
            try:
                geohash = geohash2.encode(lat, lng, precision=10)
            except:
                geohash = None
        
        # Main fountain record
        fountains.append((
            fountain.get('id', fountain_id),
            fountain.get('name', 'Unnamed Fountain'),
            fountain.get('description', ''),
            lat,
            lng,
            geohash,
            fountain.get('type', 'fountain'),
            fountain.get('status', 'active'),
            fountain.get('waterQuality'),
            fountain.get('accessibility'),
            fountain.get('addedBy'),
            parse_date(fountain.get('addedDate'))
        ))
        
        # Tags
        for tag in fountain.get('tags', []):
            tags_data.append((
                fountain.get('id', fountain_id),
                tag
            ))
        
        # OSM data
        osm_info = fountain.get('osmData', {})
        if osm_info:
            osm_data.append((
                fountain.get('id', fountain_id),
                osm_info.get('osm_id'),
                osm_info.get('source'),
                parse_date(osm_info.get('last_updated'))
            ))
        
        # Validations
        for validation in fountain.get('validations', []):
            validations_data.append((
                fountain.get('id', fountain_id),
                validation.get('validatedBy'),
                parse_date(validation.get('validationDate')),
                validation.get('validationType'),
                validation.get('notes')
            ))
        
        # Photos
        for photo in fountain.get('photos', []):
            photos_data.append((
                fountain.get('id', fountain_id),
                photo.get('url'),
                photo.get('path'),
                photo.get('uploadedBy'),
                parse_date(photo.get('uploadedDate'))
            ))
    
    # Insert fountains in batches
    print(f"Inserting {len(fountains)} fountains...")
    fountain_query = """
        INSERT INTO fountains (
            id, name, description, latitude, longitude, geohash, type, status,
            water_quality, accessibility, added_by, added_date
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (id) DO UPDATE SET
            name = EXCLUDED.name,
            description = EXCLUDED.description,
            latitude = EXCLUDED.latitude,
            longitude = EXCLUDED.longitude,
            geohash = EXCLUDED.geohash,
            type = EXCLUDED.type,
            status = EXCLUDED.status,
            water_quality = EXCLUDED.water_quality,
            accessibility = EXCLUDED.accessibility,
            added_by = EXCLUDED.added_by,
            added_date = EXCLUDED.added_date,
            updated_at = CURRENT_TIMESTAMP
    """
    
    execute_batch(cursor, fountain_query, fountains, page_size=batch_size)
    conn.commit()
    print(f"✓ Inserted {len(fountains)} fountains")
    
    # Insert tags
    if tags_data:
        print(f"Inserting {len(tags_data)} tags...")
        tags_query = """
            INSERT INTO fountain_tags (fountain_id, tag)
            VALUES (%s, %s)
            ON CONFLICT (fountain_id, tag) DO NOTHING
        """
        execute_batch(cursor, tags_query, tags_data, page_size=batch_size)
        conn.commit()
        print(f"✓ Inserted {len(tags_data)} tags")
    
    # Insert OSM data
    if osm_data:
        print(f"Inserting {len(osm_data)} OSM records...")
        osm_query = """
            INSERT INTO fountain_osm_data (fountain_id, osm_id, source, last_updated)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (fountain_id) DO UPDATE SET
                osm_id = EXCLUDED.osm_id,
                source = EXCLUDED.source,
                last_updated = EXCLUDED.last_updated
        """
        execute_batch(cursor, osm_query, osm_data, page_size=batch_size)
        conn.commit()
        print(f"✓ Inserted {len(osm_data)} OSM records")
    
    # Insert validations
    if validations_data:
        print(f"Inserting {len(validations_data)} validations...")
        validation_query = """
            INSERT INTO fountain_validations (
                fountain_id, validated_by, validation_date, validation_type, notes
            ) VALUES (%s, %s, %s, %s, %s)
        """
        execute_batch(cursor, validation_query, validations_data, page_size=batch_size)
        conn.commit()
        print(f"✓ Inserted {len(validations_data)} validations")
    
    # Insert photos
    if photos_data:
        print(f"Inserting {len(photos_data)} photos...")
        photo_query = """
            INSERT INTO fountain_photos (
                fountain_id, photo_url, photo_path, uploaded_by, uploaded_date
            ) VALUES (%s, %s, %s, %s, %s)
        """
        execute_batch(cursor, photo_query, photos_data, page_size=batch_size)
        conn.commit()
        print(f"✓ Inserted {len(photos_data)} photos")
    
    cursor.close()
    print("\n✓ Import completed successfully!")

def main():
    parser = argparse.ArgumentParser(description='Import fountain data from JSON to PostgreSQL')
    parser.add_argument('--json', default='data/world_fountains_combined.json',
                       help='Path to JSON file (default: data/world_fountains_combined.json)')
    parser.add_argument('--dbname', default=None,
                       help='Database name (default: from .env or tapmap_db)')
    parser.add_argument('--user', default=None,
                       help='Database user (default: from .env or postgres)')
    parser.add_argument('--password', default=None,
                       help='Database password (default: from .env)')
    parser.add_argument('--host', default=None,
                       help='Database host (default: from .env or localhost)')
    parser.add_argument('--port', default=None,
                       help='Database port (default: from .env or 5432)')
    parser.add_argument('--batch-size', type=int, default=1000,
                       help='Batch size for inserts (default: 1000)')
    
    args = parser.parse_args()
    
    # Get database config from args, .env, or defaults
    db_config = {
        'dbname': args.dbname or os.getenv('DB_NAME', 'tapmap_db'),
        'user': args.user or os.getenv('DB_USER', 'postgres'),
        'password': args.password or os.getenv('DB_PASSWORD', ''),
        'host': args.host or os.getenv('DB_HOST', 'localhost'),
        'port': args.port or os.getenv('DB_PORT', '5432')
    }
    
    # Connect to database
    try:
        conn = psycopg2.connect(
            dbname=db_config['dbname'],
            user=db_config['user'],
            password=db_config['password'],
            host=db_config['host'],
            port=db_config['port']
        )
        print(f"Connected to database: {db_config['dbname']}")
    except Exception as e:
        print(f"Error connecting to database: {e}")
        print(f"Using config: host={db_config['host']}, port={db_config['port']}, dbname={db_config['dbname']}, user={db_config['user']}")
        sys.exit(1)
    
    try:
        import_fountains(conn, args.json, args.batch_size)
    finally:
        conn.close()

if __name__ == '__main__':
    main()

