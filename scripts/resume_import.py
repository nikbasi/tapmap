#!/usr/bin/env python3
"""
Resume Italian Fountains Import
This script continues the import from where it left off, with better rate limiting
"""

import json
import firebase_admin
from firebase_admin import credentials, firestore
from pathlib import Path
import time
import logging
import argparse

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class ResumeImporter:
    """Resumes Italian fountains import with better rate limiting"""
    
    def __init__(self, service_account_path: str):
        """Initialize the importer with service account"""
        self.db = None
        self.service_account_path = service_account_path
        self.initialize_firebase()
    
    def initialize_firebase(self):
        """Initialize Firebase connection using service account"""
        try:
            # Initialize with service account
            cred = credentials.Certificate(self.service_account_path)
            firebase_admin.initialize_app(cred)
            logger.info("Firebase initialized with service account")
            
            self.db = firestore.client()
            logger.info("Firestore client initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to initialize Firebase: {e}")
            raise
    
    def load_italy_fountains(self, file_path: str) -> dict:
        """Load Italian fountains from JSON file"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            logger.info(f"Loaded {len(data)} fountains from {file_path}")
            return data
            
        except Exception as e:
            logger.error(f"Failed to load fountains from {file_path}: {e}")
            raise
    
    def check_existing_fountains(self) -> int:
        """Check how many fountains are already in the database"""
        try:
            fountains_ref = self.db.collection('fountains')
            italy_fountains = fountains_ref.where('importSource', '==', 'italy_osm').get()
            
            # Handle both old and new Firestore API versions
            if hasattr(italy_fountains, 'docs'):
                existing_count = len(italy_fountains.docs)
            else:
                existing_count = len(list(italy_fountains))
            
            logger.info(f"Found {existing_count} existing Italian fountains in database")
            return existing_count
            
        except Exception as e:
            logger.error(f"Failed to check existing fountains: {e}")
            return 0
    
    def transform_fountain_data(self, fountain_data: dict) -> dict:
        """Transform fountain data to match app's data model"""
        # Extract location data
        location = fountain_data.get('location', {})
        latitude = location.get('latitude', 0.0)
        longitude = location.get('longitude', 0.0)
        
        # Transform the data to match the app's Fountain model
        transformed = {
            'name': fountain_data.get('name', 'Unnamed Fountain'),
            'description': fountain_data.get('description', ''),
            'location': firestore.GeoPoint(latitude, longitude),
            'type': fountain_data.get('type', 'fountain'),
            'status': fountain_data.get('status', 'active'),
            'waterQuality': fountain_data.get('waterQuality', 'unknown'),
            'accessibility': fountain_data.get('accessibility', 'public'),
            'addedBy': 'osm_import_italy',
            'addedDate': firestore.SERVER_TIMESTAMP,
            'validations': [],
            'photos': fountain_data.get('photos', []),
            'tags': fountain_data.get('tags', []),
            'rating': None,
            'reviewCount': 0,
            'osmData': fountain_data.get('osmData', {}),
            'importSource': 'italy_osm',
            'importDate': firestore.SERVER_TIMESTAMP
        }
        
        return transformed
    
    def import_fountains(self, fountains_data: dict, start_from: int = 0, batch_size: int = 50) -> int:
        """Import fountains into Firestore database with better rate limiting"""
        if not self.db:
            raise Exception("Firestore client not initialized")
        
        total_fountains = len(fountains_data)
        fountain_items = list(fountains_data.items())
        
        # Start from the specified position
        if start_from > 0:
            fountain_items = fountain_items[start_from:]
            logger.info(f"Resuming import from position {start_from} (fountain {start_from + 1})")
        
        remaining_fountains = len(fountain_items)
        imported_count = 0
        failed_count = 0
        
        logger.info(f"Starting import of {remaining_fountains} remaining fountains...")
        logger.info(f"Progress: {start_from}/{total_fountains} completed")
        
        # Process fountains in smaller batches with longer delays
        for i in range(0, remaining_fountains, batch_size):
            batch = fountain_items[i:i + batch_size]
            batch_start = start_from + i + 1
            batch_end = min(start_from + i + batch_size, total_fountains)
            
            logger.info(f"Processing batch {batch_start}-{batch_end} of {total_fountains}")
            
            # Create a batch write
            batch_write = self.db.batch()
            
            for fountain_id, fountain_data in batch:
                try:
                    # Transform the data
                    transformed_data = self.transform_fountain_data(fountain_data)
                    
                    # Add to batch
                    doc_ref = self.db.collection('fountains').document(fountain_id)
                    batch_write.set(doc_ref, transformed_data)
                    
                except Exception as e:
                    logger.error(f"Failed to transform fountain {fountain_id}: {e}")
                    failed_count += 1
                    continue
            
            # Commit the batch with retry logic
            max_retries = 3
            for retry in range(max_retries):
                try:
                    batch_write.commit()
                    imported_count += len(batch)
                    logger.info(f"✅ Successfully imported batch {batch_start}-{batch_end}")
                    
                    # Longer delay to avoid rate limits
                    time.sleep(1.0)  # 1 second delay between batches
                    
                    break  # Success, exit retry loop
                    
                except Exception as e:
                    if "Quota exceeded" in str(e) or "429" in str(e):
                        wait_time = (retry + 1) * 30  # Progressive backoff: 30s, 60s, 90s
                        logger.warning(f"⚠️  Rate limit hit, waiting {wait_time} seconds... (retry {retry + 1}/{max_retries})")
                        time.sleep(wait_time)
                        
                        if retry == max_retries - 1:
                            logger.error(f"❌ Failed to commit batch after {max_retries} retries: {e}")
                            failed_count += len(batch)
                        else:
                            continue  # Try again
                    else:
                        logger.error(f"❌ Failed to commit batch {batch_start}-{batch_end}: {e}")
                        failed_count += len(batch)
                        break
            
            # Progress update every 10 batches
            if (i // batch_size + 1) % 10 == 0:
                progress = (start_from + i + batch_size) / total_fountains * 100
                logger.info(f"📊 Progress: {progress:.1f}% ({start_from + i + batch_size}/{total_fountains})")
        
        logger.info(f"Import completed: {imported_count} imported, {failed_count} failed")
        return imported_count
    
    def verify_import(self, expected_total: int) -> bool:
        """Verify that the import was successful"""
        try:
            # Count fountains in the database
            fountains_ref = self.db.collection('fountains')
            italy_fountains = fountains_ref.where('importSource', '==', 'italy_osm').get()
            
            # Handle both old and new Firestore API versions
            if hasattr(italy_fountains, 'docs'):
                actual_count = len(italy_fountains.docs)
            else:
                actual_count = len(list(italy_fountains))
            
            logger.info(f"Verification: Found {actual_count} Italian fountains in database (expected: {expected_total})")
            
            # Check if we have at least 90% of expected fountains
            success_rate = actual_count / expected_total if expected_total > 0 else 0
            if success_rate >= 0.9:
                logger.info(f"✅ Import verification successful ({success_rate:.1%} success rate)")
                return True
            else:
                logger.warning(f"⚠️  Import verification warning ({success_rate:.1%} success rate)")
                return False
                
        except Exception as e:
            logger.error(f"Failed to verify import: {e}")
            return False

def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='Resume Italian fountains import with better rate limiting')
    parser.add_argument('--key-file', required=True, help='Path to Firebase service account JSON file')
    parser.add_argument('--data-file', default='./data/fountains_firebase_italy_all.json', 
                       help='Path to the Italian fountains JSON file')
    parser.add_argument('--batch-size', type=int, default=50, 
                       help='Batch size for database operations (smaller for rate limiting)')
    parser.add_argument('--start-from', type=int, default=0, 
                       help='Start importing from this position (0-based index)')
    
    args = parser.parse_args()
    
    # Check if service account file exists
    key_file = Path(args.key_file)
    if not key_file.exists():
        logger.error(f"Service account key file not found: {key_file}")
        return
    
    # Check if data file exists
    data_file = Path(args.data_file)
    if not data_file.exists():
        logger.error(f"Data file not found: {data_file}")
        return
    
    try:
        # Initialize importer
        logger.info("Initializing Italian Fountains Importer...")
        importer = ResumeImporter(str(key_file))
        
        # Check existing fountains
        existing_count = importer.check_existing_fountains()
        
        # Load fountain data
        logger.info("Loading fountain data...")
        fountains_data = importer.load_italy_fountains(str(data_file))
        
        # Determine start position
        start_position = args.start_from
        if start_position == 0 and existing_count > 0:
            # Estimate start position based on existing count
            start_position = existing_count
            logger.info(f"Auto-detected start position: {start_position} (based on existing fountains)")
        
        # Import fountains
        logger.info("Starting import process...")
        start_time = time.time()
        
        imported_count = importer.import_fountains(fountains_data, start_position, args.batch_size)
        
        import_time = time.time() - start_time
        
        # Verify import
        logger.info("Verifying import...")
        verification_passed = importer.verify_import(len(fountains_data))
        
        # Print summary
        print(f"\n📊 Import Summary:")
        print(f"   Total fountains in file: {len(fountains_data)}")
        print(f"   Started from position: {start_position}")
        print(f"   Successfully imported: {imported_count}")
        print(f"   Import time: {import_time:.1f} seconds")
        print(f"   Verification: {'✅ PASSED' if verification_passed else '⚠️  WARNING'}")
        
        if imported_count > 0:
            print(f"\n🚰 Next steps:")
            print(f"   1. Check your Firebase console to see the imported fountains")
            print(f"   2. Test the app to ensure fountains display correctly")
            
            # If not all fountains imported, show resume command
            if start_position + imported_count < len(fountains_data):
                next_position = start_position + imported_count
                print(f"   3. Resume import from where you left off:")
                print(f"      python resume_import.py --key-file firebase-service-account.json --start-from {next_position}")
        else:
            print(f"\n❌ Import failed - check the logs for errors")
            
    except Exception as e:
        logger.error(f"Import failed: {e}")
        return

if __name__ == "__main__":
    main()
