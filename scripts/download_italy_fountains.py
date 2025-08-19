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

    # Initialize downloader with Italy bounding box
    downloader = FountainDownloader()
    
    # Italy bounding box (south, west, north, east)
    italy_bbox = "35.5,6.7,47.1,18.5"
    
    print("Starting Italy fountain download...")
    print(f"Bounding box: {italy_bbox}")
    
    try:
        # Download fountains
        fountains = downloader.download_fountains(bbox=italy_bbox)
        
        if fountains:
            print(f"Downloaded {len(fountains)} fountains")
            
            # Export to Firebase format - save with the name expected by the Dart script
            output_file = Path("italy_data_fixed/fountains_firebase_20250817_010551.json")
            output_file.parent.mkdir(exist_ok=True)  # Create directory if it doesn't exist
            DataExporter.to_firebase_json(fountains, str(output_file))
            
            print(f"Exported to: {output_file}")
        else:
            print("No fountains found")
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
