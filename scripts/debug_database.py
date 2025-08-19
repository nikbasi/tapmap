#!/usr/bin/env python3
"""
Debug script to investigate why geohash queries aren't working.
"""

import firebase_admin
from firebase_admin import credentials, firestore
import sys
import os

def debug_database():
    """Debug the database to find the issue."""
    
    # Initialize Firebase Admin SDK
    try:
        service_account_path = os.path.join(os.path.dirname(__file__), 'firebase-service-account.json')
        if os.path.exists(service_account_path):
            cred = credentials.Certificate(service_account_path)
            firebase_admin.initialize_app(cred)
            print("✅ Initialized Firebase with service account")
        else:
            firebase_admin.initialize_app()
            print("✅ Initialized Firebase with default credentials")
    except Exception as e:
        print(f"❌ Failed to initialize Firebase: {e}")
        return
    
    # Get Firestore client
    db = firestore.client()
    
    try:
        print("\n🔍 STEP 1: Basic database info")
        print("=" * 50)
        
        # Get total count
        fountains_ref = db.collection('fountains')
        total_docs = list(fountains_ref.limit(1).stream())
        if total_docs:
            # Get total count by checking a sample
            sample = total_docs[0]
            print(f"📊 Collection 'fountains' exists")
        
        # Count total documents
        total_count = 0
        for doc in fountains_ref.stream():
            total_count += 1
            if total_count % 10000 == 0:
                print(f"   Counted {total_count} documents...")
        
        print(f"📊 Total fountains: {total_count}")
        
        print("\n🔍 STEP 2: Check field structure")
        print("=" * 50)
        
        # Get a few sample documents to see the structure
        sample_docs = list(fountains_ref.limit(5).stream())
        
        for i, doc in enumerate(sample_docs):
            data = doc.to_dict()
            print(f"\n📄 Sample document {i+1}: {doc.id}")
            print(f"   Fields: {list(data.keys())}")
            
            # Check specific fields
            if 'location' in data:
                loc = data['location']
                print(f"   Location: {loc.latitude}, {loc.longitude}")
            
            if 'status' in data:
                print(f"   Status: {data['status']}")
            
            if 'geohash' in data:
                print(f"   geohash: {data['geohash']}")
            
            if 'geohash3' in data:
                print(f"   geohash3: {data['geohash3']}")
            
            if 'geohash4' in data:
                print(f"   geohash4: {data['geohash4']}")
        
        print("\n🔍 STEP 3: Test specific queries")
        print("=" * 50)
        
        # Test 1: Basic query without geohash
        print("🧪 Test 1: Basic query (status = 'active')")
        try:
            basic_query = fountains_ref.where('status', '==', 'active').limit(3).stream()
            basic_results = list(basic_query)
            print(f"   ✅ Basic query returned: {len(basic_results)} results")
            
            if basic_results:
                first_doc = basic_results[0].to_dict()
                print(f"   First result: {first_doc.get('name', 'Unknown')}")
                print(f"   Location: {first_doc.get('location', 'No location')}")
        except Exception as e:
            print(f"   ❌ Basic query failed: {e}")
        
        # Test 2: Query with geohash3
        print("\n🧪 Test 2: Query with geohash3 = 'sr7'")
        try:
            geohash3_query = fountains_ref.where('status', '==', 'active').where('geohash3', '==', 'sr7').limit(3).stream()
            geohash3_results = list(geohash3_query)
            print(f"   ✅ geohash3 query returned: {len(geohash3_results)} results")
            
            if geohash3_results:
                for doc in geohash3_results:
                    data = doc.to_dict()
                    loc = data.get('location')
                    if loc:
                        print(f"   Found: {data.get('name', 'Unknown')} at {loc.latitude}, {loc.longitude}")
        except Exception as e:
            print(f"   ❌ geohash3 query failed: {e}")
        
        # Test 3: Query with geohash (5-char)
        print("\n🧪 Test 3: Query with geohash = 'sr7bh'")
        try:
            geohash_query = fountains_ref.where('status', '==', 'active').where('geohash', '==', 'sr7bh').limit(3).stream()
            geohash_results = list(geohash_query)
            print(f"   ✅ geohash query returned: {len(geohash_results)} results")
            
            if geohash_results:
                for doc in geohash_results:
                    data = doc.to_dict()
                    loc = data.get('location')
                    if loc:
                        print(f"   Found: {data.get('name', 'Unknown')} at {loc.latitude}, {loc.longitude}")
        except Exception as e:
            print(f"   ❌ geohash query failed: {e}")
        
        # Test 4: Check if there are any fountains in Rome area
        print("\n🧪 Test 4: Check for fountains in Rome area (geohash starting with 'sfj')")
        try:
            # Get a few fountains and check their geohash
            rome_area_count = 0
            total_checked = 0
            
            for doc in fountains_ref.where('status', '==', 'active').limit(1000).stream():
                total_checked += 1
                data = doc.to_dict()
                
                if 'geohash3' in data and data['geohash3']:
                    if data['geohash3'].startswith('sfj'):
                        rome_area_count += 1
                        if rome_area_count <= 3:  # Show first 3
                            loc = data.get('location')
                            if loc:
                                print(f"   Rome area fountain: {data.get('name', 'Unknown')} at {loc.latitude}, {loc.longitude} (geohash3: {data['geohash3']})")
                
                if total_checked % 100 == 0:
                    print(f"   Checked {total_checked} documents...")
            
            print(f"   📍 Found {rome_area_count} fountains in Rome area (geohash3 starting with 'sfj') out of {total_checked} checked")
            
        except Exception as e:
            print(f"   ❌ Rome area check failed: {e}")
        
        print("\n🔍 STEP 5: Check geohash field distribution")
        print("=" * 50)
        
        # Count fountains with each geohash field
        geohash3_count = 0
        geohash4_count = 0
        geohash5_count = 0
        
        for doc in fountains_ref.where('status', '==', 'active').limit(10000).stream():
            data = doc.to_dict()
            
            if 'geohash3' in data and data['geohash3']:
                geohash3_count += 1
            
            if 'geohash4' in data and data['geohash4']:
                geohash4_count += 1
            
            if 'geohash' in data and data['geohash']:
                geohash5_count += 1
        
        print(f"📊 Out of 10,000 active fountains checked:")
        print(f"   geohash3 field populated: {geohash3_count}")
        print(f"   geohash4 field populated: {geohash4_count}")
        print(f"   geohash field populated: {geohash5_count}")
        
    except Exception as e:
        print(f"❌ Error during debugging: {e}")
    
    finally:
        # Clean up
        try:
            firebase_admin.delete_app(firebase_admin.get_app())
            print("\n✅ Firebase app cleaned up")
        except:
            pass

if __name__ == "__main__":
    print("🚀 Database Debug Script")
    print("=" * 50)
    debug_database()
    print("\n" + "=" * 50)
    print("✨ Debug completed!")

