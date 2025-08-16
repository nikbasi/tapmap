#!/usr/bin/env python3
"""
Test script to examine the structure of Italian fountains data
This helps us understand the data before importing to Firebase
"""

import json
from pathlib import Path
import sys

def examine_data_structure(file_path: str):
    """Examine the structure of the fountain data"""
    try:
        print(f"🔍 Examining data structure from: {file_path}")
        print("=" * 60)
        
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        print(f"📊 Total fountains: {len(data)}")
        print()
        
        if not data:
            print("❌ No data found in file")
            return
        
        # Get first fountain to examine structure
        first_fountain_id = list(data.keys())[0]
        first_fountain = data[first_fountain_id]
        
        print(f"🏗️  Data structure of first fountain (ID: {first_fountain_id}):")
        print("-" * 40)
        
        def print_structure(obj, indent=0):
            if isinstance(obj, dict):
                for key, value in obj.items():
                    if isinstance(value, (dict, list)):
                        print("  " * indent + f"📁 {key}:")
                        print_structure(value, indent + 1)
                    else:
                        print("  " * indent + f"📄 {key}: {value}")
            elif isinstance(obj, list):
                if obj:
                    print("  " * indent + f"📋 List with {len(obj)} items:")
                    if len(obj) <= 3:
                        for i, item in enumerate(obj):
                            print("  " * (indent + 1) + f"[{i}]: {item}")
                    else:
                        print("  " * (indent + 1) + f"[0]: {obj[0]}")
                        print("  " * (indent + 1) + f"[1]: {obj[1]}")
                        print("  " * (indent + 1) + f"... and {len(obj) - 2} more")
                else:
                    print("  " * indent + "📋 Empty list")
        
        print_structure(first_fountain)
        print()
        
        # Sample a few more fountains to see variations
        print("🔍 Sampling additional fountains for structure consistency:")
        print("-" * 40)
        
        sample_count = min(5, len(data))
        sample_ids = list(data.keys())[:sample_count]
        
        for i, fountain_id in enumerate(sample_ids[1:], 1):
            fountain = data[fountain_id]
            print(f"\n📋 Fountain {i+1} (ID: {fountain_id}):")
            
            # Check key differences
            keys = set(fountain.keys())
            first_keys = set(first_fountain.keys())
            
            if keys == first_keys:
                print("  ✅ Same structure as first fountain")
            else:
                missing_in_first = keys - first_keys
                missing_in_current = first_keys - keys
                
                if missing_in_first:
                    print(f"  ⚠️  Extra keys: {', '.join(missing_in_first)}")
                if missing_in_current:
                    print(f"  ⚠️  Missing keys: {', '.join(missing_in_current)}")
        
        print()
        print("=" * 60)
        print("📝 Summary:")
        print(f"   • Data file contains {len(data)} fountains")
        print(f"   • Each fountain has {len(first_fountain)} main fields")
        print(f"   • Main fields: {', '.join(first_fountain.keys())}")
        print()
        print("💡 Next steps:")
        print("   1. Review the data structure above")
        print("   2. Ensure Firebase authentication is set up")
        print("   3. Run the import script to add fountains to database")
        
    except Exception as e:
        print(f"❌ Error examining data: {e}")
        return False
    
    return True

def main():
    """Main function"""
    data_file = Path("./data/fountains_firebase_italy_all.json")
    
    if not data_file.exists():
        print(f"❌ Data file not found: {data_file}")
        print("💡 Make sure you've downloaded the Italian fountains data first")
        return False
    
    return examine_data_structure(str(data_file))

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
