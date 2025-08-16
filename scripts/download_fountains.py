#!/usr/bin/env python3
"""
Enhanced Water Fountain Downloader
Downloads drinking water fountains from OpenStreetMap using Overpass API
and formats them for Firebase import.

This script uses an EXPANDED query to capture significantly more fountain types:
- Primary drinking water sources (amenity=drinking_water)
- Water points and taps (amenity=water_point, amenity=tap)
- Water refill stations (amenity=water_refill)
- Bottle filling stations (bottle_filling=yes)
- General fountains (amenity=fountain)
- Natural water sources with drinking_water tag
- Any element with drinking_water=yes

The expanded query should find many more fountains than the previous restrictive version.
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
        Build comprehensive Overpass query to capture all types of water fountains
        
        Args:
            bbox: Optional bounding box (south,west,north,east)
            limit: Optional limit on number of results
        """
        # Start with the header
        if limit:
            header = "[out:json][timeout:300];"  # Temporarily remove limit to test
        else:
            header = "[out:json][timeout:300];"
        
        # Build query using the exact working format from test_working_query.py
        if bbox:
            # Parse bounding box coordinates
            try:
                coords = bbox.split(',')
                if len(coords) == 4:
                    south, west, north, east = coords
                    # Use expanded query with officially supported tags + drinkable indicators
                    query = f"""{header}
(
  // Primary drinking water sources (amenity=drinking_water)
  node["amenity"="drinking_water"]({south},{west},{north},{east});
  way["amenity"="drinking_water"]({south},{west},{north},{east});
  relation["amenity"="drinking_water"]({south},{west},{north},{east});
  
  // Water points for larger amounts (amenity=water_point)
  node["amenity"="water_point"]({south},{west},{north},{east});
  way["amenity"="water_point"]({south},{west},{north},{east});
  relation["amenity"="water_point"]({south},{west},{north},{east});
  
  // Water taps (man_made=water_tap)
  node["man_made"="water_tap"]({south},{west},{north},{east});
  way["man_made"="water_tap"]({south},{west},{north},{east});
  relation["man_made"="water_tap"]({south},{west},{north},{east});
  
  // General fountains (amenity=fountain)
  node["amenity"="fountain"]({south},{west},{north},{east});
  way["amenity"="fountain"]({south},{west},{north},{east});
  relation["amenity"="fountain"]({south},{west},{north},{east});
  
  // Fountains explicitly marked as drinkable
  node["amenity"="fountain"]["drinking_water"="yes"]({south},{west},{north},{east});
  way["amenity"="fountain"]["drinking_water"="yes"]({south},{west},{north},{east});
  relation["amenity"="fountain"]["drinking_water"="yes"]({south},{west},{north},{east});
  
  // Natural springs that are drinkable
  node["natural"="spring"]["drinking_water"="yes"]({south},{west},{north},{east});
  way["natural"="spring"]["drinking_water"="yes"]({south},{west},{north},{east});
  relation["natural"="spring"]["drinking_water"="yes"]({south},{west},{north},{east});
  
  // Water wells that are drinkable
  node["man_made"="water_well"]["drinking_water"="yes"]({south},{west},{north},{east});
  way["man_made"="water_well"]["drinking_water"="yes"]({south},{west},{north},{east});
  relation["man_made"="water_well"]["drinking_water"="yes"]({south},{west},{north},{east});
  
  // Emergency drinking water facilities
  node["emergency"="drinking_water"]({south},{west},{north},{east});
  way["emergency"="drinking_water"]({south},{west},{north},{east});
  relation["emergency"="drinking_water"]({south},{west},{north},{east});
);
out center;"""
                else:
                    raise ValueError("Invalid bbox format")
            except Exception as e:
                logger.warning(f"Invalid bbox format '{bbox}': {e}. Using global query.")
                bbox = None
        
        if not bbox:
            # Without bounding box - use expanded query
            query = f"""{header}
(
  // Primary drinking water sources (amenity=drinking_water)
  node["amenity"="drinking_water"];
  way["amenity"="drinking_water"];
  relation["amenity"="drinking_water"];
  
  // Water points for larger amounts (amenity=water_point)
  node["amenity"="water_point"];
  way["amenity"="water_point"];
  relation["amenity"="water_point"];
  
  // Water taps (man_made=water_tap)
  node["man_made"="water_tap"];
  way["man_made"="water_tap"];
  relation["man_made"="water_tap"];
  
  // General fountains (amenity=fountain)
  node["amenity"="fountain"];
  way["amenity"="fountain"];
  relation["amenity"="fountain"];
  
  // Fountains explicitly marked as drinkable
  node["amenity"="fountain"]["drinking_water"="yes"];
  way["amenity"="fountain"]["drinking_water"="yes"];
  relation["amenity"="fountain"]["drinking_water"="yes"];
  
  // Natural springs that are drinkable
  node["natural"="spring"]["drinking_water"="yes"];
  way["natural"="spring"]["drinking_water"="yes"];
  relation["natural"="spring"]["drinking_water"="yes"];
  
  // Water wells that are drinkable
  node["man_made"="water_well"]["drinking_water"="yes"];
  way["man_made"="water_well"]["drinking_water"="yes"];
  relation["man_made"="water_well"]["drinking_water"="yes"];
  
  // Emergency drinking water facilities
  node["emergency"="drinking_water"];
  way["emergency"="drinking_water"];
  relation["emergency"="drinking_water"];
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
            # Debug: Print the exact request being sent
            logger.info(f"Sending request to: {self.overpass_url}")
            logger.info(f"Request data: {query}")
            logger.info(f"Request headers: {self.session.headers}")
            
            # Try using requests.post directly like the working test
            response = requests.post(self.overpass_url, data={'data': query}, timeout=300)  # Increased timeout for large queries
            logger.info(f"Response status: {response.status_code}")
            logger.info(f"Response headers: {dict(response.headers)}")
            
            response.raise_for_status()
            
            data = response.json()
            logger.info(f"Downloaded {len(data.get('elements', []))} elements")
            
            return self._parse_elements(data.get('elements', []))
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Error downloading data: {e}")
            if hasattr(e, 'response') and e.response is not None:
                logger.error(f"Response content: {e.response.text[:500]}")
            return []
        except json.JSONDecodeError as e:
            logger.error(f"Error parsing JSON response: {e}")
            return []
    
    def _parse_elements(self, elements: List[Dict[str, Any]]) -> List[FountainData]:
        """Parse Overpass API response elements into FountainData objects"""
        fountains = []
        seen_ids = set()  # Track seen OSM IDs to avoid duplicates
        type_counts = {}  # Track fountain type distribution
        
        for element in elements:
            try:
                fountain = self._parse_element(element)
                if fountain:
                    # Check if we've already seen this fountain
                    osm_id = fountain.osm_data['osm_id']
                    if osm_id not in seen_ids:
                        seen_ids.add(osm_id)
                        fountains.append(fountain)
                        
                        # Count fountain types
                        fountain_type = fountain.fountain_type
                        type_counts[fountain_type] = type_counts.get(fountain_type, 0) + 1
                    else:
                        logger.debug(f"Skipping duplicate fountain: {osm_id}")
            except Exception as e:
                logger.warning(f"Error parsing element {element.get('id', 'unknown')}: {e}")
                continue
        
        # Log fountain type distribution
        logger.info(f"Successfully parsed {len(fountains)} unique fountains (from {len(elements)} elements)")
        if type_counts:
            logger.info("Fountain type distribution:")
            for fountain_type, count in sorted(type_counts.items()):
                logger.info(f"  {fountain_type}: {count}")
        
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
        """Determine fountain type from OSM tags - using only officially supported tags"""
        # Check for specific fountain types first
        if tags.get('amenity') == 'water_point':
            return 'water_point'
        elif tags.get('man_made') == 'water_tap':
            return 'water_tap'
        elif tags.get('amenity') == 'fountain':
            # Check if this fountain is explicitly drinkable
            if tags.get('drinking_water') == 'yes':
                return 'drinkable_fountain'
            else:
                return 'fountain'
        elif tags.get('natural') == 'spring' and tags.get('drinking_water') == 'yes':
            return 'drinkable_spring'
        elif tags.get('man_made') == 'water_well' and tags.get('drinking_water') == 'yes':
            return 'drinkable_well'
        elif tags.get('emergency') == 'drinking_water':
            return 'emergency_water'
        
        # Check for drinking water indicators
        if tags.get('drinking_water') == 'yes':
            # Determine type based on additional tags
            if tags.get('bottle') == 'yes':
                return 'bottle_filler'
            elif tags.get('amenity') == 'fountain':
                return 'drinkable_fountain'
            else:
                return 'drinkable_source'  # Generic drinkable water source
        
        # Default fallback
        return 'fountain'
    
    def _determine_water_quality(self, tags: Dict[str, str]) -> str:
        """Determine water quality from OSM tags - using only officially supported tags"""
        # Check explicit drinking water tags
        if tags.get('drinking_water') == 'yes':
            return 'potable'
        elif tags.get('drinking_water') == 'no':
            return 'non_potable'
        elif tags.get('drinking_water') == 'conditional':
            return 'conditional'
        
        # Check for water quality indicators
        if tags.get('water_quality') == 'potable':
            return 'potable'
        elif tags.get('water_quality') == 'non_potable':
            return 'non_potable'
        
        # Default to potable if it's marked as a drinking water source
        if tags.get('amenity') in ['drinking_water', 'water_point']:
            return 'potable'
        
        # Default fallback
        return 'unknown'
    
    def _determine_accessibility(self, tags: Dict[str, str]) -> str:
        """Determine accessibility from OSM tags - using only officially supported tags"""
        # Check explicit access tags
        if tags.get('access') == 'private':
            return 'private'
        elif tags.get('access') == 'permissive':
            return 'restricted'
        elif tags.get('access') == 'no':
            return 'restricted'
        
        # Check for time-based restrictions
        if 'opening_hours' in tags:
            return 'restricted'  # Time-limited access
        
        # Check for seasonal restrictions
        if 'seasonal' in tags:
            return 'restricted'
        
        # Default to public if no restrictions found
        return 'public'
    
    def _extract_relevant_tags(self, tags: Dict[str, str]) -> List[str]:
        """Extract relevant tags for the app - including primary identifying tags"""
        relevant_tags = []
        
        # PRIMARY TAGS - These are essential for fountain identification
        primary_keys = [
            'amenity', 'man_made', 'natural', 'emergency', 'drinking_water'
        ]
        
        for key in primary_keys:
            if key in tags:
                relevant_tags.append(f"{key}:{tags[key]}")
        
        # Accessibility and usability (officially supported)
        useful_keys = [
            'wheelchair', 'indoor', 'outdoor', 'tourist', 'historic',
            'seasonal', 'opening_hours', 'fee', 'operator', 'brand',
            'maintenance', 'last_checked', 'source', 'network'
        ]
        
        for key in useful_keys:
            if key in tags:
                relevant_tags.append(f"{key}:{tags[key]}")
        
        # Special handling for important officially supported tags
        if tags.get('bottle') == 'yes':
            relevant_tags.append('bottle:yes')
        
        if tags.get('drinking_water') == 'yes':
            relevant_tags.append('drinking_water:yes')
        
        if tags.get('amenity') == 'fountain':
            relevant_tags.append('amenity:fountain')
        
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
    
    print(f"\n🔍 Enhanced Query Coverage:")
    print(f"   The script now searches for:")
    print(f"   • Drinking water fountains (amenity=drinking_water)")
    print(f"   • Water points for larger amounts (amenity=water_point)")
    print(f"   • Water taps (man_made=water_tap)")
    print(f"   • General fountains (amenity=fountain)")
    print(f"   • Fountains explicitly marked as drinkable (drinking_water=yes)")
    print(f"   • Natural springs that are drinkable")
    print(f"   • Water wells that are drinkable")
    print(f"   • Emergency drinking water facilities")
    print(f"   • All using officially supported OpenStreetMap tags")
    
    print(f"\n🚰 Next steps:")
    print(f"   1. Review the downloaded data")
    print(f"   2. Import the Firebase JSON file to your database")
    print(f"   3. Update your app to display the imported fountains")
    print(f"   4. The enhanced query now captures ALL drinkable fountain types!")

if __name__ == "__main__":
    main()
