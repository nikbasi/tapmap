#!/usr/bin/env python3
"""
World Water Fountain Downloader
Downloads drinking water fountains from OpenStreetMap for the entire world
by automatically dividing the world into small regions with streaming to avoid memory issues.
"""

import json
import time
import logging
from pathlib import Path
from typing import List, Dict, Any, Optional
import requests
from dataclasses import dataclass
from datetime import datetime

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
    
    def build_query(self, bbox: Optional[str] = None) -> str:
        """
        Build comprehensive Overpass query to capture all types of water fountains
        
        Args:
            bbox: Optional bounding box (south,west,north,east)
        """
        # Start with the header - use extended timeout for global queries
        if not bbox:
            header = "[out:json][timeout:3600];"  # 60 minutes timeout for global queries
        else:
            header = "[out:json][timeout:900];"  # 15 minutes timeout for regional queries
        
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
    
    def download_fountains(self, bbox: Optional[str] = None, max_retries: int = 5) -> Optional[List[FountainData]]:
        """
        Download fountain data from Overpass API with retry logic for rate limiting
        
        Args:
            bbox: Optional bounding box (south,west,north,east)
            max_retries: Maximum number of retries for rate-limited requests
            
        Returns:
            List of FountainData objects
        """
        query = self.build_query(bbox)
        logger.debug(f"Downloading fountains with query:\n{query}")
        
        # Show progress for large queries
        if bbox:
            logger.info("📡 Downloading region...")
        
        for attempt in range(max_retries):
            try:
                # Use extended timeout for global queries, extended timeout for large regions
                if not bbox:
                    response = requests.post(self.overpass_url, data={'data': query}, timeout=3600)  # 60 minutes timeout for global queries
                else:
                    response = requests.post(self.overpass_url, data={'data': query}, timeout=1800)  # 30 minutes timeout for large regions
                
                logger.debug(f"Response status: {response.status_code}")
                
                # Handle rate limiting (429)
                if response.status_code == 429:
                    # Check for Retry-After header
                    retry_after = response.headers.get('Retry-After')
                    if retry_after:
                        wait_time = int(retry_after)
                    else:
                        # Exponential backoff: 2^attempt seconds, max 60 seconds
                        wait_time = min(2 ** attempt, 60)
                    
                    if attempt < max_retries - 1:
                        logger.warning(f"⏳ Rate limited (429). Waiting {wait_time} seconds before retry {attempt + 1}/{max_retries}...")
                        time.sleep(wait_time)
                        continue
                    else:
                        logger.error("❌ Rate limited (429). Max retries reached. Please wait and try again later.")
                        return None
                
                # Handle gateway timeout (504) - server is overloaded
                if response.status_code == 504:
                    # Longer wait for gateway timeouts - server needs time to recover
                    wait_time = min(10 * (attempt + 1), 120)  # 10s, 20s, 30s... up to 120s
                    
                    if attempt < max_retries - 1:
                        logger.warning(f"⏳ Gateway timeout (504). Server may be overloaded. Waiting {wait_time} seconds before retry {attempt + 1}/{max_retries}...")
                        time.sleep(wait_time)
                        continue
                    else:
                        logger.error("❌ Gateway timeout (504). Max retries reached. Server may be overloaded. This region will be marked as failed and can be retried later.")
                        return None
                
                response.raise_for_status()
                
                # Check response content for errors
                response_text = response.text
                logger.debug(f"Response content (first 2000 chars): {response_text[:2000]}")
                
                data = response.json()
                
                # Check for Overpass API errors in the response
                if 'remark' in data:
                    logger.warning(f"⚠️  Overpass API remark: {data['remark']}")
                if 'error' in data:
                    logger.error(f"❌ Overpass API error: {data['error']}")
                    return None
                
                elements = data.get('elements', [])
                logger.info(f"Downloaded {len(elements)} elements")
                
                return self._parse_elements(elements)
                
            except requests.exceptions.Timeout:
                if not bbox:
                    logger.error("⏰ Global request timed out. This is expected for world-wide queries.")
                    logger.error("💡 Consider using regional downloads instead.")
                else:
                    logger.error("⏰ Request timed out after 30 minutes. The region may be too large.")
                    logger.error("💡 Try using a smaller region or add --limit to reduce results.")
                return None
            except requests.exceptions.HTTPError as e:
                if e.response:
                    status_code = e.response.status_code
                    # Handle 429 and 504 errors with retry logic
                    if status_code == 429 or status_code == 504:
                        # These are handled by the retry logic above, but if we get here
                        # it means raise_for_status() was called, so we need to retry
                        if attempt < max_retries - 1:
                            wait_time = min(10 * (attempt + 1), 120) if status_code == 504 else min(2 ** attempt, 60)
                            logger.warning(f"⏳ HTTP {status_code} error. Waiting {wait_time} seconds before retry {attempt + 1}/{max_retries}...")
                            time.sleep(wait_time)
                            continue
                        else:
                            logger.error(f"❌ HTTP {status_code} error. Max retries reached.")
                            return None
                
                logger.error(f"❌ HTTP Error downloading data: {e}")
                if hasattr(e, 'response') and e.response is not None:
                    logger.error(f"Response content: {e.response.text[:500]}")
                
                # For other HTTP errors, return None to indicate failure
                return None
            except requests.exceptions.RequestException as e:
                logger.error(f"❌ Error downloading data: {e}")
                if hasattr(e, 'response') and e.response is not None:
                    logger.error(f"Response content: {e.response.text[:500]}")
                return None
            except json.JSONDecodeError as e:
                logger.error(f"❌ Error parsing JSON response: {e}")
                return None
        
        # If we get here, all retries failed
        logger.error(f"❌ Failed to download after {max_retries} attempts")
        # Return None to indicate failure (vs empty list which means no fountains found)
        return None
    
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


def generate_world_regions(region_size: float = 10.0) -> Dict[str, str]:
    """
    Dynamically generate bounding boxes covering the entire world
    
    Args:
        region_size: Size of each region in degrees (default: 10° for good balance)
                    Smaller values = more regions but more reliable
        
    Returns:
        Dictionary mapping region names to bounding boxes (south,west,north,east)
    """
    regions = {}
    
    # World bounds: -90 to 90 latitude, -180 to 180 longitude
    lat_min, lat_max = -90.0, 90.0
    lon_min, lon_max = -180.0, 180.0
    
    region_id = 0
    
    # Generate regions by iterating through latitude and longitude
    lat = lat_min
    while lat < lat_max:
        lon = lon_min
        while lon < lon_max:
            # Calculate bounding box for this region
            south = lat
            north = min(lat + region_size, lat_max)
            west = lon
            east = min(lon + region_size, lon_max)
            
            # Create region name
            region_name = f"region_{region_id:04d}_lat_{south:.1f}_{north:.1f}_lon_{west:.1f}_{east:.1f}"
            
            # Format bounding box as "south,west,north,east"
            bbox = f"{south:.1f},{west:.1f},{north:.1f},{east:.1f}"
            
            regions[region_name] = bbox
            region_id += 1
            
            lon += region_size
        
        lat += region_size
    
    return regions


class DynamicWorldDownloader:
    """Downloads world fountains using dynamically generated regions"""
    
    def __init__(self, output_dir: str, regions: Dict[str, str]):
        self.downloader = FountainDownloader()
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        self.regions = regions
        self.total_fountains = 0
        self.region_results = {}
        self.failed_regions = []
        
        # Create progress tracking file
        self.progress_file = self.output_dir / "download_progress.json"
        self.load_progress()
    
    def load_progress(self):
        """Load progress from previous runs"""
        if self.progress_file.exists():
            try:
                with open(self.progress_file, 'r') as f:
                    progress = json.load(f)
                    self.region_results = progress.get('completed_regions', {})
                    self.total_fountains = progress.get('total_fountains', 0)
                    self.failed_regions = progress.get('failed_regions', [])
                logger.info(f"📊 Loaded progress: {len(self.region_results)} regions completed, {self.total_fountains} fountains")
            except Exception as e:
                logger.warning(f"⚠️  Could not load progress: {e}")
    
    def save_progress(self):
        """Save current progress"""
        progress = {
            'completed_regions': self.region_results,
            'total_fountains': self.total_fountains,
            'failed_regions': self.failed_regions,
            'timestamp': time.time()
        }
        with open(self.progress_file, 'w') as f:
            json.dump(progress, f, indent=2)
    
    def download_region_streaming(self, region_name: str, bbox: str) -> int:
        """Download fountains for a specific region and save immediately to file"""
        logger.info(f"🌍 Downloading: {region_name}")
        
        region_file = self.output_dir / f"{region_name}_fountains_firebase.json"
        
        try:
            # Download with extended timeout for large regions
            fountains = self.downloader.download_fountains(bbox=bbox)
            
            if fountains:
                # Save immediately to file (no memory accumulation)
                DataExporter.to_firebase_json(fountains, str(region_file))
                
                # Update progress (only metadata, not the actual data)
                self.region_results[region_name] = {
                    'count': len(fountains),
                    'file': str(region_file),
                    'bbox': bbox,
                    'timestamp': time.time()
                }
                self.total_fountains += len(fountains)
                
                # Save progress after each successful region
                self.save_progress()
                
                logger.info(f"✅ {region_name}: Downloaded and saved {len(fountains)} fountains to {region_file}")
                return len(fountains)
            elif fountains is None:
                # Download failed after all retries - don't mark as completed, add to failed_regions
                logger.error(f"❌ {region_name}: Download failed after all retries. Will retry on next run.")
                if region_name not in self.failed_regions:
                    self.failed_regions.append(region_name)
                # Don't add to region_results - let it be retried on next run
                self.save_progress()
                return 0
            else:
                # Empty list means no fountains found (legitimate - mark as completed)
                logger.warning(f"⚠️  {region_name}: No fountains found")
                self.region_results[region_name] = {
                    'count': 0,
                    'file': str(region_file),
                    'bbox': bbox,
                    'timestamp': time.time()
                }
                self.save_progress()
                return 0
                
        except Exception as e:
            logger.error(f"❌ {region_name}: Error downloading - {e}")
            if region_name not in self.failed_regions:
                self.failed_regions.append(region_name)
            # Don't add to region_results - let it be retried
            self.save_progress()
            return 0
    
    def download_all_regions_streaming(self) -> Dict[str, Any]:
        """Download all world regions with streaming approach"""
        logger.info("🚀 Starting dynamic world fountain download...")
        logger.info(f"📊 Total regions: {len(self.regions)}")
        logger.info(f"💾 Output directory: {self.output_dir}")
        logger.info(f"🔄 Progress will be saved after each region")
        
        start_time = time.time()
        
        # Skip already completed regions
        remaining_regions = {k: v for k, v in self.regions.items() 
                           if k not in self.region_results}
        
        if remaining_regions:
            logger.info(f"📊 Skipping {len(self.regions) - len(remaining_regions)} already completed regions")
            logger.info(f"📊 Processing {len(remaining_regions)} remaining regions")
        else:
            logger.info(f"🎉 All regions already completed!")
            return self.region_results
        
        for region_name, bbox in remaining_regions.items():
            region_start = time.time()
            fountain_count = self.download_region_streaming(region_name, bbox)
            region_time = time.time() - region_start
            
            logger.info(f"⏱️  {region_name}: {fountain_count} fountains in {region_time:.1f}s")
            
            # Longer delay between regions to avoid rate limiting
            # Overpass API recommends being respectful with request frequency
            wait_time = 5  # 5 seconds between requests
            logger.debug(f"⏳ Waiting {wait_time} seconds before next region...")
            time.sleep(wait_time)
        
        total_time = time.time() - start_time
        logger.info(f"🎉 Dynamic world download completed in {total_time:.1f}s")
        logger.info(f"📊 Total fountains: {self.total_fountains:,}")
        
        if self.failed_regions:
            logger.warning(f"⚠️  Failed regions: {len(self.failed_regions)}")
        
        return self.region_results
    
    def create_combined_file(self) -> str:
        """Create a combined file by reading individual region files (streaming approach)"""
        combined_file = self.output_dir / "world_fountains_combined.json"
        
        logger.info(f"🔄 Creating combined file from individual region files...")
        
        try:
            all_fountains = {}
            total_regions = 0
            
            # Read each region file and combine
            for region_name, region_info in self.region_results.items():
                if region_info.get('count', 0) > 0:
                    region_file = Path(region_info['file'])
                    if region_file.exists():
                        with open(region_file, 'r') as f:
                            region_data = json.load(f)
                            all_fountains.update(region_data)  # Merge dictionaries
                            total_regions += 1
                            logger.info(f"📊 Added {len(region_data)} fountains from {region_name}")
            
            # Write combined file
            with open(combined_file, 'w') as f:
                json.dump(all_fountains, f, indent=2)
            
            logger.info(f"💾 Combined file created: {len(all_fountains)} fountains from {total_regions} regions")
            return str(combined_file)
            
        except Exception as e:
            logger.error(f"❌ Error creating combined file: {e}")
            return None


def main():
    """Main function for dynamic world fountain download"""
    
    print("🚀 Starting DYNAMIC world fountain download...")
    print("🌍 Automatically dividing the world into small regions")
    print("💾 Saves each region immediately to avoid memory issues")
    print("🔄 Progress is saved after each region (can resume if interrupted)")
    print()
    
    # Generate regions dynamically (10° chunks for good balance)
    # You can adjust region_size: smaller = more regions but more reliable
    region_size = 10.0
    print(f"📐 Generating regions with {region_size}° chunks...")
    world_regions = generate_world_regions(region_size=region_size)
    print(f"📊 Generated {len(world_regions)} regions covering the entire world")
    print()
    
    # Create output directory
    output_dir = Path("./data")
    output_dir.mkdir(exist_ok=True)
    
    try:
        # Create downloader with dynamic regions
        # We'll use a modified version that accepts custom regions
        downloader = DynamicWorldDownloader(str(output_dir), world_regions)
        
        # Download all regions with streaming
        region_results = downloader.download_all_regions_streaming()
        
        # Create combined file
        print(f"\n🔄 Creating combined file...")
        combined_file = downloader.create_combined_file()
        
        # Final summary
        print(f"\n🎉 Dynamic world download completed!")
        print(f"📊 Total fountains: {downloader.total_fountains:,}")
        print(f"🌍 Regions processed: {len(world_regions)}")
        print(f"✅ Completed regions: {len(region_results)}")
        print(f"❌ Failed regions: {len(downloader.failed_regions)}")
        print(f"📁 Output directory: {output_dir}")
        if combined_file:
            print(f"📁 Combined file: {combined_file}")
        print(f"💾 Progress file: {downloader.progress_file}")
        
        if downloader.failed_regions:
            print(f"\n❌ Failed Regions ({len(downloader.failed_regions)}):")
            for region in downloader.failed_regions[:10]:  # Show first 10
                print(f"   {region}")
            if len(downloader.failed_regions) > 10:
                print(f"   ... and {len(downloader.failed_regions) - 10} more")
        
        print(f"\n🔄 Next steps:")
        print(f"   1. Review the combined file for database import")
        print(f"   2. Re-run the script to resume any failed regions")
        print(f"   3. Adjust region_size if needed (smaller = more reliable but slower)")
        
    except KeyboardInterrupt:
        print(f"\n⏹️  Download interrupted by user")
        if 'downloader' in locals():
            print(f"📊 Fountains downloaded so far: {downloader.total_fountains:,}")
        print(f"📁 Partial results saved to: {output_dir}")
        print(f"🔄 Progress saved - you can resume by running the script again")
    except Exception as e:
        print(f"\n❌ Error during download: {e}")
        print(f"📁 Partial results may be saved to: {output_dir}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()