#!/usr/bin/env python3
"""
Check if a specific fountain exists in the Firebase database
"""

import firebase_admin
from firebase_admin import credentials, firestore
import json

def check_fountain_in_db():
    """Check if the specific fountain exists in the database"""
    
    # Initialize Firebase
    try:
        cred = credentials.Certificate('./firebase-service-account.json')
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        print("✅ Firebase initialized successfully")
    except Exception as e:
        print(f"❌ Failed to initialize Firebase: {e}")
        return
    
    # The fountain we're looking for
    target_lat = 40.0743409
    target_lon = 15.5195816
    target_tags = ["amenity:drinking_water", "man_made:water_tap"]
    
    print(f"\n🔍 Looking for fountain at coordinates: {target_lat}, {target_lon}")
    print(f"Expected tags: {target_tags}")
    
    try:
        # Search for fountains near these coordinates (within 100 meters)
        fountains_ref = db.collection('fountains')
        
        # Get all fountains and search in memory (since we don't have geospatial indexes)
        all_fountains = fountains_ref.limit(1000).get()
        
        print(f"\n📊 Checking {len(all_fountains)} fountains from database...")
        
        found_fountains = []
        for doc in all_fountains:
            fountain_data = doc.to_dict()
            location = fountain_data.get('location')
            
            # Handle Firestore GeoPoint objects
            if hasattr(location, 'latitude') and hasattr(location, 'longitude'):
                lat = location.latitude
                lon = location.longitude
            elif isinstance(location, dict):
                lat = location.get('latitude', 0)
                lon = location.get('longitude', 0)
            else:
                continue
                
            # Check if coordinates are close (within 100 meters)
            import math
            distance = math.sqrt((lat - target_lat)**2 + (lon - target_lon)**2)
            
            if distance < 0.001:  # Roughly 100 meters
                fountain_tags = fountain_data.get('tags', [])
                print(f"\n📍 Found nearby fountain:")
                print(f"   ID: {doc.id}")
                print(f"   Name: {fountain_data.get('name', 'Unnamed')}")
                print(f"   Location: {lat}, {lon}")
                print(f"   Distance: {distance * 111000:.1f} meters")
                print(f"   Type: {fountain_data.get('type', 'unknown')}")
                print(f"   Tags: {fountain_tags}")
                
                # Check if it has the expected tags
                has_amenity = any('amenity:drinking_water' in tag for tag in fountain_tags)
                has_water_tap = any('man_made:water_tap' in tag for tag in fountain_tags)
                
                if has_amenity and has_water_tap:
                    print("   ✅ MATCHES EXPECTED TAGS!")
                    found_fountains.append(doc.id)
                else:
                    print("   ⚠️  Missing expected tags")
        
        if not found_fountains:
            print(f"\n❌ No fountain found at coordinates {target_lat}, {target_lon}")
            print("This fountain might not be in the database yet.")
            
            # Check if we have any fountains in the general area (within 1km)
            print(f"\n🔍 Checking for any fountains in the general area...")
            area_fountains = []
            for doc in all_fountains:
                fountain_data = doc.to_dict()
                location = fountain_data.get('location')
                
                # Handle Firestore GeoPoint objects
                if hasattr(location, 'latitude') and hasattr(location, 'longitude'):
                    lat = location.latitude
                    lon = location.longitude
                elif isinstance(location, dict):
                    lat = location.get('latitude', 0)
                    lon = location.get('longitude', 0)
                else:
                    continue
                
                distance = math.sqrt((lat - target_lat)**2 + (lon - target_lon)**2)
                if distance < 0.01:  # Roughly 1km
                    area_fountains.append({
                        'id': doc.id,
                        'name': fountain_data.get('name', 'Unnamed'),
                        'lat': lat,
                        'lon': lon,
                        'distance': distance * 111000,
                        'type': fountain_data.get('type', 'unknown')
                    })
            
            if area_fountains:
                print(f"Found {len(area_fountains)} fountains within 1km:")
                for f in sorted(area_fountains, key=lambda x: x['distance'])[:5]:
                    print(f"   • {f['name']} at {f['lat']:.6f}, {f['lon']:.6f} ({f['distance']:.0f}m)")
            else:
                print("No fountains found in the area.")
        
        else:
            print(f"\n✅ Found {len(found_fountains)} matching fountain(s) in database!")
            
    except Exception as e:
        print(f"❌ Error querying database: {e}")

if __name__ == "__main__":
    check_fountain_in_db()
