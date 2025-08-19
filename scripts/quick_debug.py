#!/usr/bin/env python3
"""
Quick debug script to test specific queries without streaming issues.
"""

import firebase_admin
from firebase_admin import credentials, firestore
import sys
import os

def quick_debug():
    """Quick debug without streaming issues."""
    
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
        print("\n🔍 Testing specific queries...")
        print("=" * 50)
        
        fountains_ref = db.collection('fountains')
        
        # Test 1: Basic query
        print("🧪 Test 1: Basic query (status = 'active')")
        try:
            basic_query = fountains_ref.where('status', '==', 'active').limit(5)
            basic_results = list(basic_query.stream())
            print(f"   ✅ Basic query returned: {len(basic_results)} results")
            
            if basic_results:
                first_doc = basic_results[0].to_dict()
                print(f"   First result: {first_doc.get('name', 'Unknown')}")
                if 'location' in first_doc:
                    loc = first_doc['location']
                    print(f"   Location: {loc.latitude}, {loc.longitude}")
                print(f"   All fields: {list(first_doc.keys())}")
        except Exception as e:
            print(f"   ❌ Basic query failed: {e}")
        
        # Test 2: Query with geohash3
        print("\n🧪 Test 2: Query with geohash3 = 'sr7'")
        try:
            geohash3_query = fountains_ref.where('status', '==', 'active').where('geohash3', '==', 'sr7').limit(5)
            geohash3_results = list(geohash3_query.stream())
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
            geohash_query = fountains_ref.where('status', '==', 'active').where('geohash', '==', 'sr7bh').limit(5)
            geohash_results = list(geohash_query.stream())
            print(f"   ✅ geohash query returned: {len(geohash_results)} results")
            
            if geohash_results:
                for doc in geohash_results:
                    data = doc.to_dict()
                    loc = data.get('location')
                    if loc:
                        print(f"   Found: {data.get('name', 'Unknown')} at {loc.latitude}, {loc.longitude}")
        except Exception as e:
            print(f"   ❌ geohash query failed: {e}")
        
        # Test 3b: Query with geohash5 field
        print("\n🧪 Test 3b: Query with geohash5 = 'sr7bh'")
        try:
            geohash5_query = fountains_ref.where('status', '==', 'active').where('geohash5', '==', 'sr7bh').limit(5)
            geohash5_results = list(geohash5_query.stream())
            print(f"   ✅ geohash5 query returned: {len(geohash5_results)} results")
            
            if geohash5_results:
                for doc in geohash5_results:
                    data = doc.to_dict()
                    loc = data.get('location')
                    if loc:
                        print(f"   Found: {data.get('name', 'Unknown')} at {loc.latitude}, {loc.longitude}")
        except Exception as e:
            print(f"   ❌ geohash5 query failed: {e}")
        
        # Test 3c: Check what geohash5 values exist
        print("\n🧪 Test 3c: Check what geohash5 values exist")
        try:
            sample_query = fountains_ref.where('status', '==', 'active').limit(20)
            sample_results = list(sample_query.stream())
            
            geohash5_values = set()
            for doc in sample_results:
                data = doc.to_dict()
                if 'geohash5' in data and data['geohash5']:
                    geohash5_values.add(data['geohash5'])
            
            if geohash5_values:
                print(f"   Found geohash5 values: {sorted(list(geohash5_values))}")
            else:
                print(f"   ❌ No geohash5 field found!")
                
        except Exception as e:
            print(f"   ❌ geohash5 check failed: {e}")
        
        # Test 4: Check what geohash values actually exist
        print("\n🧪 Test 4: Check what geohash3 values exist")
        try:
            # Get a few documents and see what geohash3 values they have
            sample_query = fountains_ref.where('status', '==', 'active').limit(20)
            sample_results = list(sample_query.stream())
            
            geohash3_values = set()
            for doc in sample_results:
                data = doc.to_dict()
                if 'geohash3' in data and data['geohash3']:
                    geohash3_values.add(data['geohash3'])
            
            print(f"   Found geohash3 values: {sorted(list(geohash3_values))}")
            
            # Check if any start with 'sfj' (Rome area)
            rome_geohashes = [g for g in geohash3_values if g.startswith('sfj')]
            if rome_geohashes:
                print(f"   Rome area geohashes: {rome_geohashes}")
            else:
                print(f"   ❌ No fountains in Rome area found!")
                
        except Exception as e:
            print(f"   ❌ geohash3 check failed: {e}")
        
        # Test 5: Test the exact query the Flutter app is making
        print("\n🧪 Test 5: Test the exact Flutter app query")
        try:
            # This is what the Flutter app is trying to query
            flutter_query = fountains_ref.where('status', '==', 'active').where('geohash4', '==', 'sfjy')
            flutter_results = list(flutter_query.stream())
            print(f"   ✅ Flutter query (geohash4='sfjy') returned: {len(flutter_results)} results")
            
            if flutter_results:
                for doc in flutter_results:
                    data = doc.to_dict()
                    loc = data.get('location')
                    if loc:
                        print(f"   Found: {data.get('name', 'Unknown')} at {loc.latitude}, {loc.longitude}")
        except Exception as e:
            print(f"   ❌ Flutter query failed: {e}")
        
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
    print("🚀 Quick Database Debug Script")
    print("=" * 50)
    quick_debug()
    print("\n" + "=" * 50)
    print("✨ Quick debug completed!")
