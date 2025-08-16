#!/usr/bin/env python3
"""
Test script to import a small subset of Italian fountains
Useful for testing the import process before running the full import
"""

import json
import firebase_admin
from firebase_admin import credentials, firestore
from pathlib import Path
import logging

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def test_import_small():
    """Test import with a small subset of fountains"""
    
    data_file = Path("./data/fountains_firebase_italy_all.json")
    
    if not data_file.exists():
        print("❌ Data file not found: fountains_firebase_italy_all.json")
        return
    
    try:
        # Load the data
        with open(data_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        print(f"✅ Loaded {len(data)} fountains from data file")
        
        # Take only first 10 fountains for testing
        test_fountains = dict(list(data.items())[:10])
        print(f"🧪 Testing with {len(test_fountains)} fountains")
        
        # Initialize Firebase (use default credentials for testing)
        try:
            firebase_admin.initialize_app()
            print("✅ Firebase initialized with default credentials")
        except Exception as e:
            print(f"⚠️  Firebase already initialized: {e}")
        
        db = firestore.client()
        print("✅ Firestore client ready")
        
        # Test import with small batch
        print("\n🚰 Testing import process...")
        
        batch = db.batch()
        imported_count = 0
        
        for fountain_id, fountain_data in test_fountains.items():
            try:
                # Transform the data
                transformed_data = {
                    'name': fountain_data.get('name', 'Unnamed Fountain'),
                    'description': fountain_data.get('description', ''),
                    'location': firestore.GeoPoint(
                        fountain_data['location']['latitude'],
                        fountain_data['location']['longitude']
                    ),
                    'type': fountain_data.get('type', 'fountain'),
                    'status': fountain_data.get('status', 'active'),
                    'waterQuality': fountain_data.get('waterQuality', 'unknown'),
                    'accessibility': fountain_data.get('accessibility', 'public'),
                    'addedBy': 'osm_import_italy_test',
                    'addedDate': firestore.SERVER_TIMESTAMP,
                    'validations': [],
                    'photos': fountain_data.get('photos', []),
                    'tags': fountain_data.get('tags', []),
                    'rating': None,
                    'reviewCount': 0,
                    'osmData': fountain_data.get('osmData', {}),
                    'importSource': 'italy_osm_test',
                    'importDate': firestore.SERVER_TIMESTAMP
                }
                
                # Add to batch
                doc_ref = db.collection('fountains').document(fountain_id)
                batch.set(doc_ref, transformed_data)
                imported_count += 1
                
            except Exception as e:
                print(f"❌ Failed to transform fountain {fountain_id}: {e}")
                continue
        
        # Commit the batch
        if imported_count > 0:
            print(f"📝 Committing batch with {imported_count} fountains...")
            batch.commit()
            print(f"✅ Successfully imported {imported_count} test fountains")
            
            # Verify import
            print("\n🔍 Verifying import...")
            test_fountains_ref = db.collection('fountains')
            test_results = test_fountains_ref.where('importSource', '==', 'italy_osm_test').get()
            
            actual_count = len(test_results.docs)
            print(f"📊 Found {actual_count} test fountains in database")
            
            if actual_count == imported_count:
                print("✅ Test import verification successful!")
                print("\n🚰 Ready for full import!")
            else:
                print(f"⚠️  Test import verification warning: expected {imported_count}, got {actual_count}")
        else:
            print("❌ No fountains were prepared for import")
            
    except Exception as e:
        print(f"❌ Test import failed: {e}")
        return False
    
    return True

if __name__ == "__main__":
    print("🧪 Testing Italian Fountains Import (Small Batch)")
    print("=" * 50)
    
    success = test_import_small()
    
    if success:
        print("\n🎉 Test import completed successfully!")
        print("You can now run the full import with confidence.")
    else:
        print("\n❌ Test import failed. Check the logs above.")
    
    print("\n💡 Next steps:")
    print("   1. Check your Firebase console for test fountains")
    print("   2. Verify the data looks correct")
    print("   3. Run the full import: python import_italy_fountains.py")


