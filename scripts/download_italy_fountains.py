#!/usr/bin/env python3
"""
Italy Water Fountain Downloader
Downloads all drinking water fountains in Italy from OpenStreetMap
and exports them in Firebase format for database import.

This script uses the working fountain downloader.
"""

from download_fountains import FountainDownloader, DataExporter
from pathlib import Path
import time

def main():
    """Download all fountains in Italy"""
    
    # Create output directory
    output_dir = Path("./data")
    output_dir.mkdir(exist_ok=True)
    
    # Initialize downloader
    downloader = FountainDownloader()
    
    # Italy bounding box (south,west,north,east)
    # Covers from Sicily in the south to the Alps in the north
    # From Sardinia in the west to the Adriatic coast in the east
    italy_bbox = "35.5,6.7,47.1,18.5"
    
    print("🇮🇹 Downloading all water fountains in Italy...")
    print(f"Bounding box: {italy_bbox}")
    print("This covers the entire country including:")
    print("  - Sicily and Sardinia")
    print("  - Mainland Italy")
    print("  - Alpine regions")
    print("  - Mediterranean islands")
    print()
    
    # Download fountains
    print("⏳ Starting download (this may take several minutes)...")
    start_time = time.time()
    
    fountains = downloader.download_fountains(
        bbox=italy_bbox,
        limit=None  # No limit - get all fountains in Italy
    )
    
    download_time = time.time() - start_time
    
    if not fountains:
        print("❌ No fountains found in Italy")
        return
    
    print(f"✅ Download complete in {download_time:.1f} seconds!")
    print(f"🚰 Found {len(fountains)} water fountains across Italy!")
    print()
    
    # Show some examples from different regions
    print("📍 Sample fountains from different Italian regions:")
    
    # Group fountains by rough geographic regions
    northern_fountains = [f for f in fountains if f.latitude > 44.0]
    central_fountains = [f for f in fountains if 41.0 <= f.latitude <= 44.0]
    southern_fountains = [f for f in fountains if f.latitude < 41.0]
    
    if northern_fountains:
        print(f"  🏔️  Northern Italy (Alps & Po Valley): {len(northern_fountains)} fountains")
        sample = northern_fountains[0]
        print(f"     Example: {sample.name or 'Unnamed'} at {sample.latitude:.4f}, {sample.longitude:.4f}")
    
    if central_fountains:
        print(f"  🏛️  Central Italy (Tuscany, Lazio): {len(central_fountains)} fountains")
        sample = central_fountains[0]
        print(f"     Example: {sample.name or 'Unnamed'} at {sample.latitude:.4f}, {sample.longitude:.4f}")
    
    if southern_fountains:
        print(f"  🍋 Southern Italy (Campania, Sicily): {len(southern_fountains)} fountains")
        sample = southern_fountains[0]
        print(f"     Example: {sample.name or 'Unnamed'} at {sample.latitude:.4f}, {sample.longitude:.4f}")
    
    print()
    
    # Show fountain type distribution
    fountain_types = {}
    for fountain in fountains:
        fountain_types[fountain.fountain_type] = fountain_types.get(fountain.fountain_type, 0) + 1
    
    print("🏗️  Fountain types found:")
    for ftype, count in fountain_types.items():
        percentage = (count / len(fountains)) * 100
        print(f"     {ftype.replace('_', ' ').title()}: {count} ({percentage:.1f}%)")
    
    print()
    
    # Export to Firebase format
    timestamp = "italy_all"
    firebase_file = output_dir / f"fountains_firebase_{timestamp}.json"
    
    print("💾 Exporting to Firebase format...")
    DataExporter.to_firebase_json(fountains, str(firebase_file))
    
    print(f"✅ Exported {len(fountains)} fountains to: {firebase_file}")
    print()
    
    # File size info
    file_size = firebase_file.stat().st_size / (1024 * 1024)  # MB
    print(f"📁 File size: {file_size:.1f} MB")
    print()
    
    print("🚰 Next steps:")
    print("   1. Review the data in the JSON file")
    print("   2. Import to your Firebase database:")
    print("      - Use Firebase Console Import feature")
    print("      - Or use Firebase Admin SDK programmatically")
    print("   3. Test the data in your app")
    print("   4. Consider downloading other countries/regions")
    print()
    
    print("💡 Tips for importing to Firebase:")
    print("   - The data is already formatted for Firestore")
    print("   - Each fountain has a unique OSM-based ID")
    print("   - All coordinates are validated and accurate")
    print("   - Tags are extracted from OSM metadata")
    print("   - Water quality and accessibility are inferred from OSM data")

if __name__ == "__main__":
    main()
