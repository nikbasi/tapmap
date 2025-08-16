#!/usr/bin/env python3
"""
Search for a specific fountain in the newly downloaded fixed JSON file
"""

import json
import math

def search_fountain_in_fixed_file():
    """Search for the specific fountain in the fixed downloaded data"""
    
    # The fountain we're looking for
    target_lat = 40.0743409
    target_lon = 15.5195816
    target_tags = ["amenity:drinking_water", "man_made:water_tap"]
    
    print(f"🔍 Looking for fountain at coordinates: {target_lat}, {target_lon}")
    print(f"Expected tags: {target_tags}")
    
    # Load the newly downloaded fixed data
    try:
        with open('./italy_data_fixed/fountains_firebase_20250817_010551.json', 'r', encoding='utf-8') as f:
            data = json.load(f)
        print(f"✅ Loaded {len(data)} fountains from fixed downloaded file")
    except Exception as e:
        print(f"❌ Failed to load file: {e}")
        return
    
    # Search for the fountain
    found_fountains = []
    nearby_fountains = []
    
    for fountain_id, fountain_data in data.items():
        location = fountain_data.get('location', {})
        lat = location.get('latitude', 0)
        lon = location.get('longitude', 0)
        
        # Calculate distance
        distance = math.sqrt((lat - target_lat)**2 + (lon - target_lon)**2)
        
        # Check if it's the exact fountain (within 10 meters)
        if distance < 0.0001:  # Roughly 10 meters
            fountain_tags = fountain_data.get('tags', [])
            print(f"\n🎯 EXACT MATCH FOUND!")
            print(f"   ID: {fountain_id}")
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
                found_fountains.append(fountain_id)
            else:
                print("   ⚠️  Missing expected tags")
        
        # Check for nearby fountains (within 1km)
        elif distance < 0.01:  # Roughly 1km
            nearby_fountains.append({
                'id': fountain_id,
                'name': fountain_data.get('name', 'Unnamed'),
                'lat': lat,
                'lon': lon,
                'distance': distance * 111000,
                'type': fountain_data.get('type', 'unknown'),
                'tags': fountain_data.get('tags', [])
            })
    
    if not found_fountains:
        print(f"\n❌ No exact match found at coordinates {target_lat}, {target_lon}")
        print("This fountain was NOT captured during the download process.")
        
        if nearby_fountains:
            print(f"\n📍 Found {len(nearby_fountains)} fountains within 1km:")
            for f in sorted(nearby_fountains, key=lambda x: x['distance'])[:5]:
                print(f"   • {f['name']} at {f['lat']:.6f}, {f['lon']:.6f} ({f['distance']:.0f}m)")
                print(f"     Type: {f['type']}, Tags: {f['tags'][:3]}...")
        else:
            print("No fountains found in the area.")
    else:
        print(f"\n✅ Found {len(found_fountains)} exact match(es) in fixed downloaded data!")
        print("🎉 The tag extraction fix worked!")
    
    # Let's also check what fountain types we have in the area
    print(f"\n🔍 Fountain type distribution in the area:")
    type_counts = {}
    for f in nearby_fountains:
        fountain_type = f['type']
        type_counts[fountain_type] = type_counts.get(fountain_type, 0) + 1
    
    for fountain_type, count in sorted(type_counts.items()):
        print(f"   {fountain_type}: {count}")

if __name__ == "__main__":
    search_fountain_in_fixed_file()
