#!/usr/bin/env python3
"""
Italian Fountains Database Import Script
Imports the downloaded Italian fountains into Firestore database.
"""

import json
import firebase_admin
from firebase_admin import credentials, firestore
from pathlib import Path
import time
from datetime import datetime
import logging

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class ItalyFountainsImporter:
    """Imports Italian fountains into Firestore database"""
    
    def __init__(self, service_account_path: str = None):
        """
        Initialize the importer
        
        Args:
            service_account_path: Path to Firebase service account JSON file
        """
        self.db = None
        self.service_account_path = service_account_path
        self.initialize_firebase()
    
    def initialize_firebase(self):
        """Initialize Firebase connection"""
        try:
            if self.service_account_path and Path(self.service_account_path).exists():
                # Use service account file
                cred = credentials.Certificate(self.service_account_path)
                firebase_admin.initialize_app(cred)
                logger.info("Firebase initialized with service account")
            else:
                # Use default credentials (for local development)
                firebase_admin.initialize_app()
                logger.info("Firebase initialized with default credentials")
            
            self.db = firestore.client()
            logger.info("Firestore client initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to initialize Firebase: {e}")
            raise
    
    def load_italy_fountains(self, file_path: str) -> dict:
        """
        Load Italian fountains from JSON file
        
        Args:
            file_path: Path to the JSON file
            
        Returns:
            Dictionary of fountain data
        """
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            logger.info(f"Loaded {len(data)} fountains from {file_path}")
            return data
            
        except Exception as e:
            logger.error(f"Failed to load fountains from {file_path}: {e}")
            raise
    
    def transform_fountain_data(self, fountain_data: dict) -> dict:
        """
        Transform fountain data to match app's data model
        
        Args:
            fountain_data: Raw fountain data from JSON
            
        Returns:
            Transformed fountain data for Firestore
        """
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
            'status': 'active',  # Keep as string 'active' to match the enum parsing in Flutter
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
    
    def import_fountains(self, fountains_data: dict, batch_size: int = 500) -> int:
        """
        Import fountains into Firestore database
        
        Args:
            fountains_data: Dictionary of fountain data
            batch_size: Number of fountains to process in each batch
            
        Returns:
            Number of fountains successfully imported
        """
        if not self.db:
            raise Exception("Firestore client not initialized")
        
        total_fountains = len(fountains_data)
        imported_count = 0
        failed_count = 0
        
        logger.info(f"Starting import of {total_fountains} fountains...")
        
        # Process fountains in batches
        fountain_items = list(fountains_data.items())
        
        for i in range(0, total_fountains, batch_size):
            batch = fountain_items[i:i + batch_size]
            batch_start = i + 1
            batch_end = min(i + batch_size, total_fountains)
            
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
            
            # Commit the batch
            try:
                batch_write.commit()
                imported_count += len(batch)
                logger.info(f"Successfully imported batch {batch_start}-{batch_end}")
                
                # Small delay to avoid overwhelming the database
                time.sleep(0.1)
                
            except Exception as e:
                logger.error(f"Failed to commit batch {batch_start}-{batch_end}: {e}")
                failed_count += len(batch)
        
        logger.info(f"Import completed: {imported_count} imported, {failed_count} failed")
        return imported_count
    
    def verify_import(self, expected_count: int) -> bool:
        """
        Verify that the import was successful
        
        Args:
            expected_count: Expected number of fountains in database
            
        Returns:
            True if verification passes, False otherwise
        """
        try:
            # Count fountains in the database
            fountains_ref = self.db.collection('fountains')
            italy_fountains = fountains_ref.where('importSource', '==', 'italy_osm').get()
            
            actual_count = len(italy_fountains.docs)
            logger.info(f"Verification: Found {actual_count} Italian fountains in database (expected: {expected_count})")
            
            # Check if we have at least 90% of expected fountains
            success_rate = actual_count / expected_count if expected_count > 0 else 0
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
    import argparse
    
    parser = argparse.ArgumentParser(description='Import Italian fountains into Firestore database')
    parser.add_argument('--service-account', help='Path to Firebase service account JSON file')
    parser.add_argument('--data-file', default='./data/fountains_firebase_italy_all.json', 
                       help='Path to the Italian fountains JSON file')
    parser.add_argument('--batch-size', type=int, default=500, 
                       help='Batch size for database operations')
    
    args = parser.parse_args()
    
    # Check if data file exists
    data_file = Path(args.data_file)
    if not data_file.exists():
        logger.error(f"Data file not found: {data_file}")
        return
    
    try:
        # Initialize importer
        logger.info("Initializing Italian Fountains Importer...")
        importer = ItalyFountainsImporter(args.service_account)
        
        # Load fountain data
        logger.info("Loading fountain data...")
        fountains_data = importer.load_italy_fountains(str(data_file))
        
        # Import fountains
        logger.info("Starting import process...")
        start_time = time.time()
        
        imported_count = importer.import_fountains(fountains_data, args.batch_size)
        
        import_time = time.time() - start_time
        
        # Verify import
        logger.info("Verifying import...")
        verification_passed = importer.verify_import(len(fountains_data))
        
        # Print summary
        print(f"\n📊 Import Summary:")
        print(f"   Total fountains in file: {len(fountains_data)}")
        print(f"   Successfully imported: {imported_count}")
        print(f"   Import time: {import_time:.1f} seconds")
        print(f"   Verification: {'✅ PASSED' if verification_passed else '⚠️  WARNING'}")
        
        if imported_count > 0:
            print(f"\n🚰 Next steps:")
            print(f"   1. Check your Firebase console to see the imported fountains")
            print(f"   2. Test the app to ensure fountains display correctly")
            print(f"   3. Consider setting up regular data updates")
        else:
            print(f"\n❌ Import failed - check the logs for errors")
            
    except Exception as e:
        logger.error(f"Import failed: {e}")
        return

if __name__ == "__main__":
    main()

