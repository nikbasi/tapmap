#!/usr/bin/env python3
"""
Convert the large JSON fountain data to a Dart file for direct import.
This bypasses Flutter web asset loading issues.
"""

import json
import os
from datetime import datetime

def convert_json_to_dart():
    """Convert the large JSON file to a Dart file."""
    
    # Input file path
    input_file = "scripts/italy_data_fixed/fountains_firebase_20250817_010551.json"
    
    # Output Dart file path
    output_file = "lib/data/fountain_data.dart"
    
    print(f"🔄 Converting {input_file} to {output_file}...")
    
    # Create output directory if it doesn't exist
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    
    try:
        # Read the JSON file
        print("📖 Reading JSON file...")
        with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        print(f"✅ JSON loaded successfully. Found {len(data)} fountain entries.")
        
        # Start writing the Dart file
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("// Auto-generated fountain data file\n")
            f.write("// Generated from: fountains_firebase_20250817_010551.json\n")
            f.write("// Generated on: " + datetime.now().isoformat() + "\n\n")
            
            f.write("import 'package:water_fountain_finder/models/local_fountain.dart';\n\n")
            
            f.write("/// Sample fountain data for testing and development\n")
            f.write("/// This contains a subset of the full dataset for performance\n")
            f.write("class FountainData {\n")
            f.write("  /// Get sample fountains for testing\n")
            f.write("  static List<Map<String, dynamic>> getSampleFountains() {\n")
            f.write("    return [\n")
            
            # Process each fountain entry
            count = 0
            max_fountains = 99258  # Use the full dataset - all 99,258 fountains
            
            for fountain_id, fountain_data in data.items():
                if count >= max_fountains:
                    break
                    
                try:
                    # Extract basic info
                    name = fountain_data.get('name', 'Unknown Fountain')
                    description = fountain_data.get('description', '')
                    
                    # Handle location data
                    location = fountain_data.get('location', {})
                    if isinstance(location, dict):
                        latitude = location.get('latitude', 0.0)
                        longitude = location.get('longitude', 0.0)
                    else:
                        latitude = fountain_data.get('latitude', 0.0)
                        longitude = fountain_data.get('longitude', 0.0)
                    
                    # Skip if no valid coordinates
                    if not latitude or not longitude or latitude == 0.0 or longitude == 0.0:
                        continue
                    
                    # Extract other fields
                    fountain_type = fountain_data.get('type', 'fountain')
                    status = fountain_data.get('status', 'active')
                    water_quality = fountain_data.get('waterQuality', 'potable')
                    accessibility = fountain_data.get('accessibility', 'public')
                    added_by = fountain_data.get('addedBy', 'system')
                    added_date = fountain_data.get('addedDate', '2024-01-01T00:00:00.000Z')
                    photos = fountain_data.get('photos', [])
                    tags = fountain_data.get('tags', [])
                    osm_data = fountain_data.get('osmData')
                    
                    # Write the fountain data
                    f.write(f"      {{\n")
                    f.write(f"        'id': '{fountain_id}',\n")
                    f.write(f"        'name': {json.dumps(name)},\n")
                    f.write(f"        'description': {json.dumps(description)},\n")
                    f.write(f"        'location': {{'latitude': {latitude}, 'longitude': {longitude}}},\n")
                    f.write(f"        'type': {json.dumps(fountain_type)},\n")
                    f.write(f"        'status': {json.dumps(status)},\n")
                    f.write(f"        'waterQuality': {json.dumps(water_quality)},\n")
                    f.write(f"        'accessibility': {json.dumps(accessibility)},\n")
                    f.write(f"        'addedBy': {json.dumps(added_by)},\n")
                    f.write(f"        'addedDate': {json.dumps(added_date)},\n")
                    f.write(f"        'photos': {json.dumps(photos)},\n")
                    f.write(f"        'tags': {json.dumps(tags)},\n")
                    f.write(f"        'osmData': {json.dumps(osm_data)},\n")
                    f.write(f"      }},\n")
                    
                    count += 1
                    
                    # Progress indicator
                    if count % 100 == 0:
                        print(f"📊 Processed {count} fountains...")
                        
                except Exception as e:
                    print(f"⚠️ Error processing fountain {fountain_id}: {e}")
                    continue
            
            f.write("    ];\n")
            f.write("  }\n")
            f.write("}\n")
        
        print(f"✅ Successfully converted {count} fountains to {output_file}")
        print(f"📊 Total fountains in source: {len(data)}")
        print(f"📊 Fountains converted: {count}")
        
    except Exception as e:
        print(f"❌ Error converting file: {e}")
        return False
    
    return True

if __name__ == "__main__":
    convert_json_to_dart()
