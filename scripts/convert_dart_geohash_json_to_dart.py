#!/usr/bin/env python3
"""
Convert JSON file with Dart-calculated geohashes to Dart file
"""

import json
import os

def convert_json_to_dart():
    # Input and output file paths
    input_file = "italy_data_fixed/fountains_with_dart_geohashes.json"
    output_file = "../lib/data/dart_geohash_fountain_data.dart"
    
    print(f"🔄 Converting {input_file} to {output_file}...")
    
    try:
        # Read the JSON file
        with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        print(f"✅ JSON loaded successfully. Found {len(data)} fountain entries.")
        
        # Create the Dart file
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("// Generated from fountains_with_dart_geohashes.json\n")
            f.write("// Contains fountain data with pre-calculated Dart geohashes\n\n")
            f.write("class DartGeohashFountainData {\n")
            f.write("  static List<Map<String, dynamic>> getAllFountains() {\n")
            f.write("    return [\n")
            
            count = 0
            for fountain_id, fountain_data in data.items():
                try:
                    # Ensure the fountain has required fields
                    if 'name' not in fountain_data or 'location' not in fountain_data:
                        continue
                    
                    # Write fountain data with proper Dart formatting
                    f.write("      {\n")
                    f.write(f"        'id': '{fountain_id}',\n")
                    # Properly escape strings for Dart
                    name = json.dumps(fountain_data['name'])
                    description = json.dumps(fountain_data.get('description', ''))
                    f.write(f"        'name': {name},\n")
                    f.write(f"        'description': {description},\n")
                    
                    # Location data
                    location = fountain_data['location']
                    f.write(f"        'latitude': {location['latitude']},\n")
                    f.write(f"        'longitude': {location['longitude']},\n")
                    
                    # Other fields
                    f.write(f"        'type': '{fountain_data.get('type', 'fountain')}',\n")
                    f.write(f"        'status': '{fountain_data.get('status', 'active')}',\n")
                    f.write(f"        'waterQuality': '{fountain_data.get('waterQuality', 'unknown')}',\n")
                    f.write(f"        'accessibility': '{fountain_data.get('accessibility', 'public')}',\n")
                    f.write(f"        'addedBy': '{fountain_data.get('addedBy', 'osm_import')}',\n")
                    f.write(f"        'addedDate': '{fountain_data.get('addedDate', '')}',\n")
                    
                    # Geohash fields (pre-calculated with Dart)
                    f.write(f"        'geohashPrec5': '{fountain_data.get('geohashPrec5', '')}',\n")
                    f.write(f"        'geohashPrec4': '{fountain_data.get('geohashPrec4', '')}',\n")
                    f.write(f"        'geohashPrec3': '{fountain_data.get('geohashPrec3', '')}',\n")
                    
                    # Tags
                    tags = fountain_data.get('tags', [])
                    f.write(f"        'tags': {json.dumps(tags)},\n")
                    
                    # Validations and photos
                    f.write(f"        'validations': {json.dumps(fountain_data.get('validations', []))},\n")
                    f.write(f"        'photos': {json.dumps(fountain_data.get('photos', []))},\n")
                    
                    # OSM data
                    osm_data = fountain_data.get('osmData', {})
                    f.write(f"        'osmData': {{\n")
                    f.write(f"          'osm_id': '{osm_data.get('osm_id', '')}',\n")
                    f.write(f"          'source': '{osm_data.get('source', 'osm')}',\n")
                    f.write(f"          'last_updated': '{osm_data.get('last_updated', '')}',\n")
                    f.write(f"        }},\n")
                    
                    f.write("      },\n")
                    
                    count += 1
                    
                    # Progress indicator
                    if count % 1000 == 0:
                        print(f"📊 Processed {count} fountains...")
                        
                except Exception as e:
                    print(f"⚠️ Error processing fountain {fountain_id}: {e}")
                    continue
            
            f.write("    ];\n")
            f.write("  }\n")
            f.write("}\n")
        
        print(f"✅ Successfully converted {count} fountains to Dart file")
        print(f"📁 Output file: {output_file}")
        
        # File size info
        input_size = os.path.getsize(input_file) / (1024 * 1024)  # MB
        output_size = os.path.getsize(output_file) / (1024 * 1024)  # MB
        
        print(f"📊 File sizes:")
        print(f"   Input JSON:  {input_size:.2f} MB")
        print(f"   Output Dart: {output_size:.2f} MB")
        
    except Exception as e:
        print(f"❌ Error converting file: {e}")
        return False
    
    return True

if __name__ == "__main__":
    convert_json_to_dart()
