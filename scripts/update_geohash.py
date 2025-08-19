#!/usr/bin/env python3
"""
Script to update existing fountains in Firestore with geohash fields.
This ensures backward compatibility with the new geohash-based querying system.
"""

import firebase_admin
from firebase_admin import credentials, firestore
import geohash
import sys
import os

# Add the parent directory to the path to import utils
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def update_fountains_with_geohash():
    """Update ALL existing fountains with geohash fields (overwrite existing ones)."""
    
    # Initialize Firebase Admin SDK
    try:
        # Try to use service account key if available
        service_account_path = os.path.join(os.path.dirname(__file__), 'firebase-service-account.json')
        if os.path.exists(service_account_path):
            cred = credentials.Certificate(service_account_path)
            firebase_admin.initialize_app(cred)
            print("✅ Initialized Firebase with service account")
        else:
            # Use default credentials (for local development)
            firebase_admin.initialize_app()
            print("✅ Initialized Firebase with default credentials")
    except Exception as e:
        print(f"❌ Failed to initialize Firebase: {e}")
        return
    
    # Get Firestore client
    db = firestore.client()
    
    try:
        # Use pagination instead of streaming to avoid timeout issues
        print("🔍 Querying ALL fountains to update geohash fields...")
        
        fountains_ref = db.collection('fountains')
        batch = db.batch()
        batch_size = 0
        max_batch_size = 500  # Firestore batch limit
        updated_count = 0
        total_count = 0
        
        # Process in chunks to avoid memory issues
        chunk_size = 1000
        last_doc = None
        
        while True:
            try:
                # Query next chunk
                if last_doc:
                    query = fountains_ref.order_by('__name__').start_after(last_doc).limit(chunk_size)
                else:
                    query = fountains_ref.order_by('__name__').limit(chunk_size)
                
                docs = query.stream()
                chunk_docs = list(docs)  # Convert to list to avoid streaming issues
                
                if not chunk_docs:
                    break
                
                print(f"📄 Processing chunk of {len(chunk_docs)} fountains...")
                
                for fountain_doc in chunk_docs:
                    total_count += 1
                    fountain_data = fountain_doc.to_dict()
                    
                    # Get location data
                    location = fountain_data.get('location')
                    if not location:
                        print(f"⚠️ Fountain {fountain_doc.id} has no location data")
                        continue
                    
                    try:
                        lat = location.latitude
                        lon = location.longitude
                        
                        # Generate geohash fields (overwrite existing ones)
                        geohash_5 = geohash.encode(lat, lon, precision=5)
                        geohash_4 = geohash.encode(lat, lon, precision=4)
                        geohash_3 = geohash.encode(lat, lon, precision=3)
                        
                        # Add to batch update (always update, don't check if exists)
                        batch.update(fountain_doc.reference, {
                            'geohash': geohash_5,
                            'geohash4': geohash_4,
                            'geohash3': geohash_3,
                        })
                        
                        batch_size += 1
                        updated_count += 1
                        
                        # Commit batch when it reaches the limit
                        if batch_size >= max_batch_size:
                            print(f"📦 Committing batch of {batch_size} updates...")
                            batch.commit()
                            batch = db.batch()
                            batch_size = 0
                        
                    except Exception as e:
                        print(f"⚠️ Error processing fountain {fountain_doc.id}: {e}")
                        continue
                
                # Update last_doc for next iteration
                last_doc = chunk_docs[-1]
                
                if updated_count % 5000 == 0:
                    print(f"📊 Processed {updated_count} fountains...")
                
            except Exception as e:
                print(f"⚠️ Error processing chunk: {e}")
                # Try to continue with next chunk
                if last_doc:
                    last_doc = None  # Reset and try from beginning
                continue
        
        # Commit remaining updates
        if batch_size > 0:
            print(f"📦 Committing final batch of {batch_size} updates...")
            batch.commit()
        
        print(f"✅ Update completed!")
        print(f"   Total fountains processed: {total_count}")
        print(f"   Fountains updated: {updated_count}")
        
    except Exception as e:
        print(f"❌ Error updating fountains: {e}")
    
    finally:
        # Clean up
        try:
            firebase_admin.delete_app(firebase_admin.get_app())
            print("✅ Firebase app cleaned up")
        except:
            pass

def verify_geohash_fields():
    """Verify that geohash fields are properly set."""
    
    try:
        # Initialize Firebase Admin SDK
        service_account_path = os.path.join(os.path.dirname(__file__), 'firebase-service-account.json')
        if os.path.exists(service_account_path):
            cred = credentials.Certificate(service_account_path)
            firebase_admin.initialize_app(cred)
        else:
            firebase_admin.initialize_app()
        
        db = firestore.client()
        
        print("🔍 Verifying geohash fields...")
        
        # Sample a few fountains to check
        fountains_ref = db.collection('fountains')
        sample_fountains = fountains_ref.limit(5).stream()
        
        for fountain_doc in sample_fountains:
            fountain_data = fountain_doc.to_dict()
            location = fountain_data.get('location')
            
            if location:
                lat = location.latitude
                lon = location.longitude
                geohash_5 = fountain_data.get('geohash')
                geohash_4 = fountain_data.get('geohash4')
                geohash_3 = fountain_data.get('geohash3')
                
                print(f"📍 Fountain: {fountain_data.get('name', 'Unknown')}")
                print(f"   Location: {lat}, {lon}")
                print(f"   Geohash5: {geohash_5}")
                print(f"   Geohash4: {geohash_4}")
                print(f"   Geohash3: {geohash_3}")
                
                # Verify geohash is correct
                if geohash_5:
                    expected_geohash = geohash.encode(lat, lon, precision=5)
                    if geohash_5 == expected_geohash:
                        print("   ✅ Geohash5 is correct")
                    else:
                        print(f"   ❌ Geohash5 mismatch: expected {expected_geohash}")
                print()
        
        # Clean up
        firebase_admin.delete_app(firebase_admin.get_app())
        
    except Exception as e:
        print(f"❌ Error verifying geohash fields: {e}")

if __name__ == "__main__":
    print("🚀 Fountain Geohash Update Script")
    print("=" * 40)
    
    if len(sys.argv) > 1 and sys.argv[1] == "verify":
        verify_geohash_fields()
    else:
        update_fountains_with_geohash()
    
    print("=" * 40)
    print("✨ Script completed!")

