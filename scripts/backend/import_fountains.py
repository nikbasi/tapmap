#!/usr/bin/env python3
"""
Fountain Data Import Script
Imports fountain data from JSON files into PostgreSQL database
with automatic geohash precision calculation for efficient queries.
"""

import os
import json
import logging
import argparse
from typing import Dict, Any, List
import psycopg2
from psycopg2.extras import RealDictCursor
import geohash
from datetime import datetime
import time
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Database configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'database': os.getenv('DB_NAME', 'tapmap_db'),
    'user': os.getenv('DB_USER', 'tapmap_user'),
    'password': os.getenv('DB_PASSWORD', '$fountains.2025$'),
    'port': os.getenv('DB_PORT', '5432')
}

class FountainImporter:
    def __init__(self, db_config: Dict[str, str]):
        self.db_config = db_config
        self.conn = None
        self.cursor = None
        
    def connect(self):
        """Establish database connection"""
        try:
            self.conn = psycopg2.connect(**self.db_config)
            self.cursor = self.conn.cursor(cursor_factory=RealDictCursor)
            logger.info("Database connection established")
        except psycopg2.Error as e:
            logger.error(f"Database connection failed: {e}")
            raise
    
    def disconnect(self):
        """Close database connection"""
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
        logger.info("Database connection closed")
    
    def calculate_geohash_precisions(self, geohash_str: str) -> List[str]:
        """Calculate all precision levels for a geohash"""
        return [geohash_str[:i] for i in range(1, 13)]
    
    def prepare_fountain_data(self, fountain_data: Dict[str, Any]) -> Dict[str, Any]:
        """Prepare fountain data for database insertion"""
        try:
            # Extract location
            location = fountain_data.get('location', {})
            latitude = float(location.get('latitude', 0))
            longitude = float(location.get('longitude', 0))
            
            # Calculate geohash
            geohash_str = geohash.encode(latitude, longitude, precision=12)
            
            # Calculate all precision levels
            precision_levels = self.calculate_geohash_precisions(geohash_str)
            
            # Prepare data for insertion
            prepared_data = {
                'id': fountain_data.get('id', ''),
                'name': fountain_data.get('name', 'Unnamed Fountain'),
                'description': fountain_data.get('description', ''),
                'latitude': latitude,
                'longitude': longitude,
                'type': fountain_data.get('type', 'fountain'),
                'status': fountain_data.get('status', 'active'),
                'water_quality': fountain_data.get('waterQuality', 'potable'),
                'accessibility': fountain_data.get('accessibility', 'public'),
                'added_by': fountain_data.get('addedBy', 'osm_import'),
                'added_date': fountain_data.get('addedDate', datetime.now().isoformat()),
                'validations': json.dumps(fountain_data.get('validations', [])),
                'photos': json.dumps(fountain_data.get('photos', [])),
                'tags': json.dumps(fountain_data.get('tags', [])),
                'osm_data': json.dumps(fountain_data.get('osmData', {})),
                'geohash': geohash_str,
                'geohash_1': precision_levels[0],
                'geohash_2': precision_levels[1],
                'geohash_3': precision_levels[2],
                'geohash_4': precision_levels[3],
                'geohash_5': precision_levels[4],
                'geohash_6': precision_levels[5],
                'geohash_7': precision_levels[6],
                'geohash_8': precision_levels[7],
                'geohash_9': precision_levels[8],
                'geohash_10': precision_levels[9],
                'geohash_11': precision_levels[10],
                'geohash_12': precision_levels[11]
            }
            
            return prepared_data
            
        except Exception as e:
            logger.error(f"Error preparing fountain data: {e}")
            logger.error(f"Problematic data: {fountain_data}")
            raise
    
    def insert_fountain(self, fountain_data: Dict[str, Any]) -> bool:
        """Insert a single fountain into the database"""
        try:
            insert_query = """
            INSERT INTO fountains (
                id, name, description, latitude, longitude, type, status,
                water_quality, accessibility, added_by, added_date, validations,
                photos, tags, osm_data, geohash,
                geohash_1, geohash_2, geohash_3, geohash_4, geohash_5, geohash_6,
                geohash_7, geohash_8, geohash_9, geohash_10, geohash_11, geohash_12
            ) VALUES (
                %(id)s, %(name)s, %(description)s, %(latitude)s, %(longitude)s,
                %(type)s, %(status)s, %(water_quality)s, %(accessibility)s,
                %(added_by)s, %(added_date)s, %(validations)s, %(photos)s,
                %(tags)s, %(osm_data)s, %(geohash)s,
                %(geohash_1)s, %(geohash_2)s, %(geohash_3)s, %(geohash_4)s,
                %(geohash_5)s, %(geohash_6)s, %(geohash_7)s, %(geohash_8)s,
                %(geohash_9)s, %(geohash_10)s, %(geohash_11)s, %(geohash_12)s
            ) ON CONFLICT (id) DO UPDATE SET
                name = EXCLUDED.name,
                description = EXCLUDED.description,
                latitude = EXCLUDED.latitude,
                longitude = EXCLUDED.longitude,
                type = EXCLUDED.type,
                status = EXCLUDED.status,
                water_quality = EXCLUDED.water_quality,
                accessibility = EXCLUDED.accessibility,
                validations = EXCLUDED.validations,
                photos = EXCLUDED.photos,
                tags = EXCLUDED.tags,
                osm_data = EXCLUDED.osm_data,
                geohash = EXCLUDED.geohash,
                geohash_1 = EXCLUDED.geohash_1,
                geohash_2 = EXCLUDED.geohash_2,
                geohash_3 = EXCLUDED.geohash_3,
                geohash_4 = EXCLUDED.geohash_4,
                geohash_5 = EXCLUDED.geohash_5,
                geohash_6 = EXCLUDED.geohash_6,
                geohash_7 = EXCLUDED.geohash_7,
                geohash_8 = EXCLUDED.geohash_8,
                geohash_9 = EXCLUDED.geohash_9,
                geohash_10 = EXCLUDED.geohash_10,
                geohash_11 = EXCLUDED.geohash_11,
                geohash_12 = EXCLUDED.geohash_12,
                updated_at = CURRENT_TIMESTAMP
            """
            
            self.cursor.execute(insert_query, fountain_data)
            return True
            
        except Exception as e:
            logger.error(f"Error inserting fountain {fountain_data.get('id', 'unknown')}: {e}")
            return False
    
    def import_json_file(self, json_file_path: str, batch_size: int = 1000) -> Dict[str, int]:
        """Import fountains from a JSON file"""
        logger.info(f"Starting import from {json_file_path}")
        
        try:
            with open(json_file_path, 'r', encoding='utf-8') as file:
                data = json.load(file)
            
            total_fountains = len(data)
            logger.info(f"Found {total_fountains} fountains in JSON file")
            
            successful_imports = 0
            failed_imports = 0
            processed = 0
            
            # Process in batches for better performance
            fountain_items = list(data.items())
            
            for i in range(0, len(fountain_items), batch_size):
                batch = fountain_items[i:i + batch_size]
                
                for fountain_id, fountain_data in batch:
                    try:
                        # Add the ID if not present
                        if 'id' not in fountain_data:
                            fountain_data['id'] = fountain_id
                        
                        # Prepare data for insertion
                        prepared_data = self.prepare_fountain_data(fountain_data)
                        
                        # Insert into database
                        if self.insert_fountain(prepared_data):
                            successful_imports += 1
                        else:
                            failed_imports += 1
                        
                        processed += 1
                        
                        # Progress logging
                        if processed % 1000 == 0:
                            logger.info(f"Processed {processed}/{total_fountains} fountains")
                    
                    except Exception as e:
                        logger.error(f"Error processing fountain {fountain_id}: {e}")
                        failed_imports += 1
                        processed += 1
                
                # Commit batch
                self.conn.commit()
                logger.info(f"Committed batch {i//batch_size + 1}")
            
            # Final commit
            self.conn.commit()
            
            logger.info(f"Import completed. Successful: {successful_imports}, Failed: {failed_imports}")
            
            return {
                'total': total_fountains,
                'successful': successful_imports,
                'failed': failed_imports,
                'processed': processed
            }
            
        except Exception as e:
            logger.error(f"Error reading JSON file: {e}")
            raise
    
    def create_indexes(self):
        """Create database indexes for optimal performance"""
        logger.info("Creating database indexes...")
        
        try:
            # The schema.sql already includes these indexes, but we can recreate them if needed
            index_queries = [
                "CREATE INDEX IF NOT EXISTS idx_fountains_geohash_1 ON fountains(geohash_1)",
                "CREATE INDEX IF NOT EXISTS idx_fountains_geohash_2 ON fountains(geohash_2)",
                "CREATE INDEX IF NOT EXISTS idx_fountains_geohash_3 ON fountains(geohash_3)",
                "CREATE INDEX IF NOT EXISTS idx_fountains_geohash_4 ON fountains(geohash_4)",
                "CREATE INDEX IF NOT EXISTS idx_fountains_geohash_5 ON fountains(geohash_5)",
                "CREATE INDEX IF NOT EXISTS idx_fountains_geohash_6 ON fountains(geohash_6)",
                "CREATE INDEX IF NOT EXISTS idx_fountains_geohash_7 ON fountains(geohash_7)",
                "CREATE INDEX IF NOT EXISTS idx_fountains_geohash_8 ON fountains(geohash_8)",
                "CREATE INDEX IF NOT EXISTS idx_fountains_geohash_9 ON fountains(geohash_9)",
                "CREATE INDEX IF NOT EXISTS idx_fountains_geohash_10 ON fountains(geohash_10)",
                "CREATE INDEX IF NOT EXISTS idx_fountains_geohash_11 ON fountains(geohash_11)",
                "CREATE INDEX IF NOT EXISTS idx_fountains_geohash_12 ON fountains(geohash_12)",
                "CREATE INDEX IF NOT EXISTS idx_fountains_location ON fountains(latitude, longitude)",
                "CREATE INDEX IF NOT EXISTS idx_fountains_status ON fountains(status)",
                "CREATE INDEX IF NOT EXISTS idx_fountains_type ON fountains(type)",
                "CREATE INDEX IF NOT EXISTS idx_fountains_water_quality ON fountains(water_quality)"
            ]
            
            for query in index_queries:
                self.cursor.execute(query)
            
            self.conn.commit()
            logger.info("Database indexes created successfully")
            
        except Exception as e:
            logger.error(f"Error creating indexes: {e}")
            raise
    
    def get_import_stats(self) -> Dict[str, Any]:
        """Get statistics about the imported data"""
        try:
            # Total fountain count
            self.cursor.execute("SELECT COUNT(*) as total FROM fountains")
            total_count = self.cursor.fetchone()['total']
            
            # Count by geohash precision
            self.cursor.execute("SELECT * FROM fountain_stats_by_precision")
            precision_stats = [dict(row) for row in self.cursor.fetchall()]
            
            # Sample geohash distribution
            self.cursor.execute("""
                SELECT geohash_1, COUNT(*) as count 
                FROM fountains 
                GROUP BY geohash_1 
                ORDER BY count DESC 
                LIMIT 10
            """)
            top_geohashes = [dict(row) for row in self.cursor.fetchall()]
            
            return {
                'total_fountains': total_count,
                'precision_stats': precision_stats,
                'top_geohashes': top_geohashes,
                'timestamp': datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error getting import stats: {e}")
            raise

def main():
    parser = argparse.ArgumentParser(description='Import fountain data from JSON to PostgreSQL')
    parser.add_argument('json_file', help='Path to JSON file containing fountain data')
    parser.add_argument('--batch-size', type=int, default=1000, help='Batch size for processing (default: 1000)')
    parser.add_argument('--create-indexes', action='store_true', help='Create database indexes after import')
    parser.add_argument('--stats', action='store_true', help='Show import statistics after completion')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.json_file):
        logger.error(f"JSON file not found: {args.json_file}")
        return
    
    importer = FountainImporter(DB_CONFIG)
    
    try:
        # Connect to database
        importer.connect()
        
        # Import data
        start_time = time.time()
        import_results = importer.import_json_file(args.json_file, args.batch_size)
        end_time = time.time()
        
        # Create indexes if requested
        if args.create_indexes:
            importer.create_indexes()
        
        # Show statistics if requested
        if args.stats:
            stats = importer.get_import_stats()
            logger.info("Import Statistics:")
            logger.info(f"  Total fountains: {stats['total_fountains']}")
            logger.info(f"  Import time: {end_time - start_time:.2f} seconds")
            logger.info(f"  Import rate: {import_results['successful'] / (end_time - start_time):.2f} fountains/second")
        
        logger.info("Import process completed successfully")
        
    except Exception as e:
        logger.error(f"Import process failed: {e}")
        raise
    
    finally:
        importer.disconnect()

if __name__ == "__main__":
    main()


