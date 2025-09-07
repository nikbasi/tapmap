#!/usr/bin/env python3
"""
Migration script to move fountain data from JSON to PostgreSQL
This script handles the conversion and calculates geohash fields for efficient queries
"""

import json
import psycopg2
import psycopg2.extras
from psycopg2.extras import RealDictCursor
import argparse
import sys
import os
from datetime import datetime
import uuid
from typing import Dict, List, Any, Optional
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('migration.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class GeohashCalculator:
    """Simple geohash implementation that matches the Dart version"""
    
    BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz"
    
    @staticmethod
    def encode(latitude: float, longitude: float, precision: int = 5) -> str:
        """Encode latitude/longitude to geohash with given precision"""
        lat_min, lat_max = -90.0, 90.0
        lon_min, lon_max = -180.0, 180.0
        
        geohash = ""
        bit = 0
        ch = 0
        
        while len(geohash) < precision:
            if bit % 2 == 0:
                # Even bit: bisect longitude
                mid = (lon_min + lon_max) / 2
                if longitude >= mid:
                    ch |= (1 << (4 - bit % 5))
                    lon_min = mid
                else:
                    lon_max = mid
            else:
                # Odd bit: bisect latitude
                mid = (lat_min + lat_max) / 2
                if latitude >= mid:
                    ch |= (1 << (4 - bit % 5))
                    lat_min = mid
                else:
                    lat_max = mid
            
            bit += 1
            
            if bit % 5 == 0:
                geohash += GeohashCalculator.BASE32[ch]
                ch = 0
        
        return geohash

class PostgresMigrator:
    """Handles migration from JSON to PostgreSQL"""
    
    def __init__(self, db_config: Dict[str, Any]):
        self.db_config = db_config
        self.connection = None
        self.cursor = None
        
    def connect(self) -> bool:
        """Establish connection to PostgreSQL"""
        try:
            self.connection = psycopg2.connect(
                host=self.db_config['host'],
                port=self.db_config['port'],
                database=self.db_config['database'],
                user=self.db_config['username'],
                password=self.db_config['password']
            )
            self.cursor = self.connection.cursor(cursor_factory=RealDictCursor)
            logger.info("Connected to PostgreSQL database")
            return True
        except Exception as e:
            logger.error(f"Failed to connect to database: {e}")
            return False
    
    def disconnect(self):
        """Close database connection"""
        if self.cursor:
            self.cursor.close()
        if self.connection:
            self.connection.close()
        logger.info("Disconnected from database")
    
    def create_tables(self) -> bool:
        """Create the necessary tables if they don't exist"""
        try:
            # Read the SQL setup file
            sql_file = os.path.join(os.path.dirname(__file__), 'setup_postgres_db.sql')
            with open(sql_file, 'r') as f:
                sql_content = f.read()
            
            # Split into individual statements and execute
            statements = sql_content.split(';')
            for statement in statements:
                statement = statement.strip()
                if statement and not statement.startswith('--') and not statement.startswith('\\'):
                    self.cursor.execute(statement)
            
            self.connection.commit()
            logger.info("Database tables created successfully")
            return True
        except Exception as e:
            logger.error(f"Failed to create tables: {e}")
            self.connection.rollback()
            return False
    
    def migrate_fountain_data(self, json_file_path: str, batch_size: int = 1000) -> bool:
        """Migrate fountain data from JSON to PostgreSQL"""
        try:
            logger.info(f"Starting migration from {json_file_path}")
            
            # Load JSON data
            with open(json_file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            logger.info(f"Loaded {len(data)} fountain records from JSON")
            
            # Prepare the insert statement
            insert_sql = """
                INSERT INTO fountains (
                    id, name, description, latitude, longitude, type, status,
                    water_quality, accessibility, added_by, added_date, photos,
                    tags, rating, review_count, import_source, import_date,
                    osm_data, geohash, geohash4, geohash3, geohash2, geohash1
                ) VALUES (
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
                ) ON CONFLICT (id) DO UPDATE SET
                    name = EXCLUDED.name,
                    description = EXCLUDED.description,
                    latitude = EXCLUDED.latitude,
                    longitude = EXCLUDED.longitude,
                    type = EXCLUDED.type,
                    status = EXCLUDED.status,
                    water_quality = EXCLUDED.water_quality,
                    accessibility = EXCLUDED.accessibility,
                    photos = EXCLUDED.photos,
                    tags = EXCLUDED.tags,
                    rating = EXCLUDED.rating,
                    review_count = EXCLUDED.review_count,
                    import_source = EXCLUDED.import_source,
                    import_date = EXCLUDED.import_date,
                    osm_data = EXCLUDED.osm_data,
                    geohash = EXCLUDED.geohash,
                    geohash4 = EXCLUDED.geohash4,
                    geohash3 = EXCLUDED.geohash3,
                    geohash2 = EXCLUDED.geohash2,
                    geohash1 = EXCLUDED.geohash1,
                    updated_at = NOW()
            """
            
            # Process data in batches
            total_processed = 0
            total_skipped = 0
            
            for i in range(0, len(data), batch_size):
                batch = list(data.items())[i:i + batch_size]
                batch_data = []
                
                for fountain_id, fountain_data in batch:
                    try:
                        # Extract coordinates
                        latitude, longitude = self._extract_coordinates(fountain_data)
                        if latitude is None or longitude is None:
                            total_skipped += 1
                            continue
                        
                        # Calculate geohash fields
                        geohash = GeohashCalculator.encode(latitude, longitude, precision=5)
                        geohash4 = GeohashCalculator.encode(latitude, longitude, precision=4)
                        geohash3 = GeohashCalculator.encode(latitude, longitude, precision=3)
                        geohash2 = GeohashCalculator.encode(latitude, longitude, precision=2)
                        geohash1 = GeohashCalculator.encode(latitude, longitude, precision=1)
                        
                        # Prepare data for insertion
                        row_data = (
                            fountain_id,
                            fountain_data.get('name', ''),
                            fountain_data.get('description', ''),
                            latitude,
                            longitude,
                            fountain_data.get('type', 'fountain'),
                            fountain_data.get('status', 'active'),
                            fountain_data.get('waterQuality', 'unknown'),
                            fountain_data.get('accessibility', 'public'),
                            fountain_data.get('addedBy', 'migration'),
                            self._parse_date(fountain_data.get('addedDate')),
                            fountain_data.get('photos', []),
                            fountain_data.get('tags', []),
                            fountain_data.get('rating'),
                            fountain_data.get('reviewCount', 0),
                            fountain_data.get('importSource'),
                            self._parse_date(fountain_data.get('importDate')),
                            fountain_data.get('osmData'),
                            geohash,
                            geohash4,
                            geohash3,
                            geohash2,
                            geohash1
                        )
                        
                        batch_data.append(row_data)
                        
                    except Exception as e:
                        logger.warning(f"Error processing fountain {fountain_id}: {e}")
                        total_skipped += 1
                        continue
                
                # Insert batch
                if batch_data:
                    psycopg2.extras.execute_batch(self.cursor, insert_sql, batch_data)
                    total_processed += len(batch_data)
                    
                    # Commit every batch
                    self.connection.commit()
                    
                    logger.info(f"Processed batch {i//batch_size + 1}: {len(batch_data)} records (Total: {total_processed})")
            
            logger.info(f"Migration completed: {total_processed} records processed, {total_skipped} skipped")
            return True
            
        except Exception as e:
            logger.error(f"Migration failed: {e}")
            self.connection.rollback()
            return False
    
    def _extract_coordinates(self, fountain_data: Dict[str, Any]) -> tuple[Optional[float], Optional[float]]:
        """Extract latitude and longitude from fountain data"""
        try:
            # Try different possible coordinate formats
            if 'location' in fountain_data and isinstance(fountain_data['location'], dict):
                location = fountain_data['location']
                if 'latitude' in location and 'longitude' in location:
                    return float(location['latitude']), float(location['longitude'])
            
            if 'latitude' in fountain_data and 'longitude' in fountain_data:
                return float(fountain_data['latitude']), float(fountain_data['longitude'])
            
            return None, None
        except (ValueError, TypeError):
            return None, None
    
    def _parse_date(self, date_value: Any) -> Optional[datetime]:
        """Parse date from various formats"""
        if not date_value:
            return None
        
        try:
            if isinstance(date_value, str):
                return datetime.fromisoformat(date_value.replace('Z', '+00:00'))
            elif isinstance(date_value, (int, float)):
                return datetime.fromtimestamp(date_value / 1000)  # Assume milliseconds
            else:
                return None
        except (ValueError, TypeError):
            return None
    
    def verify_migration(self) -> bool:
        """Verify that the migration was successful"""
        try:
            # Check total count
            self.cursor.execute("SELECT COUNT(*) FROM fountains")
            total_count = self.cursor.fetchone()['count']
            
            # Check count with geohash fields
            self.cursor.execute("SELECT COUNT(*) FROM fountains WHERE geohash IS NOT NULL")
            with_geohash_count = self.cursor.fetchone()['count']
            
            # Check sample records
            self.cursor.execute("SELECT id, name, latitude, longitude, geohash FROM fountains LIMIT 5")
            sample_records = self.cursor.fetchall()
            
            logger.info(f"Migration verification:")
            logger.info(f"  Total fountains: {total_count}")
            logger.info(f"  With geohash: {with_geohash_count}")
            logger.info(f"  Sample records:")
            for record in sample_records:
                logger.info(f"    {record['id']}: {record['name']} at ({record['latitude']}, {record['longitude']}) -> {record['geohash']}")
            
            return total_count > 0 and with_geohash_count > 0
            
        except Exception as e:
            logger.error(f"Verification failed: {e}")
            return False

def main():
    parser = argparse.ArgumentParser(description='Migrate fountain data from JSON to PostgreSQL')
    parser.add_argument('json_file', help='Path to the JSON file containing fountain data')
    parser.add_argument('--host', default='localhost', help='PostgreSQL host')
    parser.add_argument('--port', type=int, default=5432, help='PostgreSQL port')
    parser.add_argument('--database', default='tapmap', help='PostgreSQL database name')
    parser.add_argument('--username', default='postgres', help='PostgreSQL username')
    parser.add_argument('--password', required=True, help='PostgreSQL password')
    parser.add_argument('--batch-size', type=int, default=1000, help='Batch size for processing')
    parser.add_argument('--create-tables', action='store_true', help='Create tables before migration')
    
    args = parser.parse_args()
    
    # Database configuration
    db_config = {
        'host': args.host,
        'port': args.port,
        'database': args.database,
        'username': args.username,
        'password': args.password
    }
    
    # Check if JSON file exists
    if not os.path.exists(args.json_file):
        logger.error(f"JSON file not found: {args.json_file}")
        sys.exit(1)
    
    # Initialize migrator
    migrator = PostgresMigrator(db_config)
    
    try:
        # Connect to database
        if not migrator.connect():
            sys.exit(1)
        
        # Create tables if requested
        if args.create_tables:
            if not migrator.create_tables():
                logger.error("Failed to create tables")
                sys.exit(1)
        
        # Perform migration
        if not migrator.migrate_fountain_data(args.json_file, args.batch_size):
            logger.error("Migration failed")
            sys.exit(1)
        
        # Verify migration
        if not migrator.verify_migration():
            logger.error("Migration verification failed")
            sys.exit(1)
        
        logger.info("Migration completed successfully!")
        
    except KeyboardInterrupt:
        logger.info("Migration interrupted by user")
        sys.exit(1)
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        sys.exit(1)
    finally:
        migrator.disconnect()

if __name__ == '__main__':
    main()


