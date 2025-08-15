#!/usr/bin/env python3
"""
Test with the exact working query syntax
"""

import requests

def test_working_italy():
    """Test with the exact query that worked earlier"""
    
    # This is the exact query that worked in our earlier test
    query = """[out:json][timeout:300];
(
  node["amenity"="drinking_water"](35.5,6.7,47.1,18.5);
  way["amenity"="drinking_water"](35.5,6.7,47.1,18.5);
  relation["amenity"="drinking_water"](35.5,6.7,47.1,18.5);
);
out center;"""
    
    print("Testing working Italy query:")
    print(f"Query:\n{query}")
    print()
    
    try:
        response = requests.post(
            "https://overpass-api.de/api/interpreter",
            data={'data': query},
            timeout=30
        )
        
        print(f"Status code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Success! Found {len(data.get('elements', []))} elements")
        else:
            print(f"❌ Failed. Response: {response.text[:200]}...")
            
    except Exception as e:
        print(f"❌ Error: {e}")

def test_simple_working():
    """Test with a simple working query"""
    
    query = """[out:json][timeout:25];
node["amenity"="drinking_water"](around:1000,40.7128,-74.0060);
out;"""
    
    print("Testing simple working query:")
    print(f"Query:\n{query}")
    print()
    
    try:
        response = requests.post(
            "https://overpass-api.de/api/interpreter",
            data={'data': query},
            timeout=30
        )
        
        print(f"Status code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Success! Found {len(data.get('elements', []))} elements")
        else:
            print(f"❌ Failed. Response: {response.text[:200]}...")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    print("🧪 Testing Working Query Syntax")
    print("=" * 40)
    print()
    
    test_simple_working()
    print()
    print("-" * 40)
    print()
    test_working_italy()
