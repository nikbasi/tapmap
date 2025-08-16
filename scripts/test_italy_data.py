#!/usr/bin/env python3
"""
Test script to verify Italian fountains data format
"""

import json
from pathlib import Path

def test_italy_data():
    """Test the Italian fountains data file"""
    
    data_file = Path("./data/fountains_firebase_italy_all.json")
    
    if not data_file.exists():
        print("❌ Data file not found: fountains_firebase_italy_all.json")
        print("Please run the download script first: download_italy_fountains.py")
        return
    
    print("🔍 Testing Italian fountains data file...")
    print(f"File: {data_file}")
    print(f"Size: {data_file.stat().st_size / (1024*1024):.1f} MB")
    print()
    
    try:
        # Load the data
        with open(data_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        print(f"✅ Successfully loaded JSON data")
        print(f"📊 Total fountains: {len(data)}")
        print()
        
        # Check data structure
        if not data:
            print("❌ No fountains found in data file")
            return
        
        # Get first fountain for structure analysis
        first_fountain_id = list(data.keys())[0]
        first_fountain = data[first_fountain_id]
        
        print("🏗️  Data structure analysis:")
        print(f"   Fountain ID format: {first_fountain_id}")
        print(f"   Fountain name: {first_fountain.get('name', 'N/A')}")
        print(f"   Location: {first_fountain.get('location', {})}")
        print(f"   Type: {first_fountain.get('type', 'N/A')}")
        print(f"   Status: {first_fountain.get('status', 'N/A')}")
        print(f"   Water Quality: {first_fountain.get('waterQuality', 'N/A')}")
        print(f"   Accessibility: {first_fountain.get('accessibility', 'N/A')}")
        print()
        
        # Check required fields
        required_fields = ['name', 'location', 'type', 'status', 'waterQuality', 'accessibility']
        missing_fields = []
        
        for field in required_fields:
            if field not in first_fountain:
                missing_fields.append(field)
        
        if missing_fields:
            print(f"⚠️  Missing required fields: {missing_fields}")
        else:
            print("✅ All required fields present")
        
        # Check location format
        location = first_fountain.get('location', {})
        if 'latitude' in location and 'longitude' in location:
            print("✅ Location format is correct")
        else:
            print("❌ Location format is incorrect")
        
        # Sample some fountains
        print()
        print("📍 Sample fountains:")
        sample_count = min(5, len(data))
        fountain_items = list(data.items())[:sample_count]
        
        for i, (fountain_id, fountain) in enumerate(fountain_items, 1):
            name = fountain.get('name', 'Unnamed')
            location = fountain.get('location', {})
            lat = location.get('latitude', 0)
            lon = location.get('longitude', 0)
            ftype = fountain.get('type', 'unknown')
            
            print(f"   {i}. {name} ({ftype}) at {lat:.4f}, {lon:.4f}")
        
        print()
        print("✅ Data format test completed successfully!")
        print("🚰 Ready for import to database")
        
    except json.JSONDecodeError as e:
        print(f"❌ Invalid JSON format: {e}")
    except Exception as e:
        print(f"❌ Error testing data: {e}")

if __name__ == "__main__":
    test_italy_data()


