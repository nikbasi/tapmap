#!/usr/bin/env python3
"""
Working Water Fountain Downloader
Downloads drinking water fountains from OpenStreetMap using Overpass API
and formats them for Firebase import.

This script uses the exact working query syntax that we've tested.
"""

import requests
import json
import logging
from typing import List, Dict, Any, Optional
from dataclasses import dataclass
from datetime import datetime
import argparse
from pathlib import Path

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

@dataclass
class FountainData:
    """Data structure for fountain information"""
    id: str
    name: str
    description: str
    latitude: float
    longitude: float
    fountain_type: str
    water_quality: str
    accessibility: str
    tags: List[str]
    osm_data: Dict[str, Any]

class FountainDownloader:
    """Downloads drinking water fountains from OpenStreetMap"""
    
    def __init__(self):
        self.overpass_url = "https://overpass-api.de/api/interpreter"
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'WaterFountainFinder/1.0'
        })
    
    def build_query(self, bbox: Optional[str] = None, limit: Optional[int] = None) -> str:
        """
        Build working Overpass query using proven syntax
        
        Args:
            bbox: Optional bounding box (south,west,north,east)
            limit: Optional limit on number of results
        """
        # Start with the header
        if limit:
            header = f"[out:json][timeout:300][limit:{limit}];"
        else:
            header = "[out:json][timeout:300];"
        
        # Build the query body using the exact working syntax
        if bbox:
            # With bounding box - using proven working syntax
            query = f"""{header}
(
  node["amenity"="drinking_water"]({bbox});
  way["amenity"="drinking_water"]({bbox});
  relation["amenity"="drinking_water"]({bbox});
);
out center;"""
        else:
            # Without bounding box
            query = f"""{header}
(
  node["amenity"="drinking_water"];
  way["amenity"="drinking_water"];
  relation["amenity"="drinking_water"];
);
out center;"""
        
        return query
    
    def download_fountains(self, bbox: Optional[str] = None, limit: Optional[int] = None) -> List[FountainData]:
        """
        Download fountain data from Overpass API
        
        Args:
            bbox: Optional bounding box (south,west,north,east)
            limit: Optional limit on number of results
            
        Returns:
            List of FountainData objects
        """
        query = self.build_query(bbox, limit)
        logger.info(f"Downloading fountains with query:\n{query}")
        
        try:
            response = self.session.post(self.overpass_url, data={'data': query})
            response.raise_for_status()
            
            data = response.json()
            logger.info(f"Downloaded {len(data.get('elements', []))} elements")
            
            return self._parse_elements(data.get('elements', []))
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Error downloading data: {e}")
            return []
        except json.JSONDecodeError as e:
            logger.error(f"Error parsing JSON response: {e}")
            return []
    
    def _parse_elements(self, elements: List[Dict[str, Any]]) -> List[FountainData]:
        """Parse Overpass API response elements into FountainData objects"""
        fountains = []
        
        for element in elements:
            try:
                fountain = self._parse_element(element)
                if fountain:
                    fountains.append(fountain)
            except Exception as e:
                logger.warning(f"Error parsing element {element.get('id', 'unknown')}: {e}")
                continue
        
        logger.info(f"Successfully parsed {len(fountains)} fountains")
        return fountains
    
    def _parse_element(self, element: Dict[str, Any]) -> Optional[FountainData]:
        """Parse a single Overpass element into FountainData"""
        element_type = element.get('type')
        element_id = element.get('id')
        
        # Get coordinates
        if element_type == 'node':
            lat = element.get('lat')
            lon = element.get('lon')
        elif element_type in ['way', 'relation']:
            center = element.get('center', {})
            lat = center.get('lat')
            lon = center.get('lon')
        else:
            return None
            
        if lat is None or lon is None:
            return None
        
        # Get tags
        tags = element.get('tags', {})
        
        # Create fountain data
        fountain = FountainData(
            id=f"osm_{element_type}_{element_id}",
            name=tags.get('name', 'Unnamed Fountain'),
            description=tags.get('description', ''),
            latitude=float(lat),
            longitude=float(lon),
            fountain_type=self._determine_fountain_type(tags),
            water_quality=self._determine_water_quality(tags),
            accessibility=self._determine_accessibility(tags),
            tags=self._extract_relevant_tags(tags),
            osm_data={
                'osm_id': f"{element_type}_{element_id}",
                'source': 'osm',
                'last_updated': datetime.now().isoformat()
            }
        )
        
        return fountain
    
    def _determine_fountain_type(self, tags: Dict[str, str]) -> str:
        """Determine fountain type from OSM tags"""
        if 'drinking_water' in tags:
            return 'fountain'
        elif 'water_point' in tags:
            return 'tap'
        elif 'water_refill' in tags:
            return 'refill_station'
        elif 'bottle_filling' in tags:
            return 'bottle_filler'
        else:
            return 'unknown'
    
    def _determine_water_quality(self, tags: Dict[str, str]) -> str:
        """Determine water quality from OSM tags"""
        if tags.get('drinking_water') == 'yes':
            return 'potable'
        elif tags.get('drinking_water') == 'no':
            return 'non_potable'
        else:
            return 'unknown'
    
    def _determine_accessibility(self, tags: Dict[str, str]) -> str:
        """Determine accessibility from OSM tags"""
        if tags.get('access') == 'private':
            return 'private'
        elif tags.get('access') == 'permissive':
            return 'restricted'
        else:
            return 'public'
    
    def _extract_relevant_tags(self, tags: Dict[str, str]) -> List[str]:
        """Extract relevant tags for the app"""
        relevant_tags = []
        
        # Add useful tags
        useful_keys = ['wheelchair', 'indoor', 'outdoor', 'tourist', 'historic']
        for key in useful_keys:
            if key in tags:
                relevant_tags.append(key)
        
        return relevant_tags

class DataExporter:
    """Exports fountain data to various formats"""
    
    @staticmethod
    def to_json(fountains: List[FountainData], filename: str):
        """Export to JSON format"""
        data = [fountain.__dict__ for fountain in fountains]
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        
        logger.info(f"Exported {len(fountains)} fountains to {filename}")
    
    @staticmethod
    def to_firebase_json(fountains: List[FountainData], filename: str):
        """Export to Firebase-compatible JSON format"""
        firebase_data = {}
        
        for fountain in fountains:
            firebase_data[fountain.id] = {
                'id': fountain.id,
                'name': fountain.name,
                'description': fountain.description,
                'location': {
                    'latitude': fountain.latitude,
                    'longitude': fountain.longitude
                },
                'type': fountain.fountain_type,
                'status': 'active',
                'waterQuality': fountain.water_quality,
                'accessibility': fountain.accessibility,
                'addedBy': 'osm_import',
                'addedDate': datetime.now().isoformat(),
                'validations': [],
                'photos': [],
                'tags': fountain.tags,
                'osmData': fountain.osm_data
            }
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(firebase_data, f, indent=2, ensure_ascii=False)
        
        logger.info(f"Exported {len(fountains)} fountains to Firebase format: {filename}")

def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='Download water fountains from OpenStreetMap')
    parser.add_argument('--bbox', help='Bounding box (south,west,north,east)')
    parser.add_argument('--limit', type=int, help='Limit number of results')
    parser.add_argument('--output-dir', default='./data', help='Output directory')
    parser.add_argument('--format', choices=['json', 'firebase'], default='firebase', help='Output format')
    
    args = parser.parse_args()
    
    # Create output directory
    output_dir = Path(args.output_dir)
    output_dir.mkdir(exist_ok=True)
    
    # Initialize downloader
    downloader = FountainDownloader()
    
    # Download fountains
    logger.info("Starting fountain download...")
    fountains = downloader.download_fountains(bbox=args.bbox, limit=args.limit)
    
    if not fountains:
        logger.error("No fountains downloaded. Exiting.")
        return
    
    logger.info(f"Successfully downloaded {len(fountains)} fountains")
    
    # Export data
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    if args.format == 'json':
        output_file = output_dir / f"fountains_{timestamp}.json"
        DataExporter.to_json(fountains, str(output_file))
    
    elif args.format == 'firebase':
        output_file = output_dir / f"fountains_firebase_{timestamp}.json"
        DataExporter.to_firebase_json(fountains, str(output_file))
    
    # Print summary
    print(f"\n📊 Download Summary:")
    print(f"   Total fountains: {len(fountains)}")
    print(f"   Output directory: {output_dir}")
    print(f"   File created: {output_file.name}")
    
    print(f"\n🚰 Next steps:")
    print(f"   1. Review the downloaded data")
    print(f"   2. Import the Firebase JSON file to your database")
    print(f"   3. Update your app to display the imported fountains")

if __name__ == "__main__":
    main()
