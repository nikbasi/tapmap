#!/usr/bin/env python3
"""
Example script showing how to download fountains for a small area
This is useful for testing the downloader before running it on larger areas.
"""

from download_fountains import FountainDownloader, DataExporter
from pathlib import Path

def main():
    """Example: Download fountains in Central Park, NYC"""
    
    # Create output directory
    output_dir = Path("./data")
    output_dir.mkdir(exist_ok=True)
    
    # Initialize downloader
    downloader = FountainDownloader()
    
    # Central Park bounding box (south,west,north,east)
    central_park_bbox = "40.7640,-73.9810,40.8000,-73.9490"
    
    print("🗽 Downloading fountains in Central Park, NYC...")
    print(f"Bounding box: {central_park_bbox}")
    print()
    
    # Download fountains
    fountains = downloader.download_fountains(
        bbox=central_park_bbox,
        limit=50  # Limit for testing
    )
    
    if not fountains:
        print("❌ No fountains found in this area")
        return
    
    print(f"✅ Found {len(fountains)} fountains!")
    print()
    
    # Show some examples
    print("📍 Sample fountains:")
    for i, fountain in enumerate(fountains[:3]):
        print(f"  {i+1}. {fountain.name or 'Unnamed'}")
        print(f"     Location: {fountain.latitude:.4f}, {fountain.longitude:.4f}")
        print(f"     Type: {fountain.fountain_type}")
        print(f"     Quality: {fountain.water_quality}")
        print()
    
    # Export to Firebase format
    timestamp = "example_central_park"
    firebase_file = output_dir / f"fountains_firebase_{timestamp}.json"
    
    DataExporter.to_firebase_json(fountains, str(firebase_file))
    
    print(f"💾 Exported {len(fountains)} fountains to: {firebase_file}")
    print()
    print("🚰 Next steps:")
    print("   1. Review the data in the JSON file")
    print("   2. Import to your Firebase database")
    print("   3. Test with a larger area if needed")

if __name__ == "__main__":
    main()
