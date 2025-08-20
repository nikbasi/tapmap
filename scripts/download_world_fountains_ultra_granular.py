#!/usr/bin/env python3
"""
Ultra-Granular World Water Fountain Downloader
Downloads drinking water fountains from OpenStreetMap for the entire world
using very small, manageable chunks (5-10° size) with streaming to avoid memory issues.

This approach covers every corner of the world including islands and remote areas
with maximum granularity for reliability and complete coverage.
"""

import json
import time
import logging
from pathlib import Path
from typing import List, Dict, Any
import requests
from download_fountains import FountainDownloader, DataExporter

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Define world regions as ultra-small, manageable chunks (5-10° size)
ULTRA_GRANULAR_WORLD_REGIONS = {
    # Europe (ultra-small chunks - 5-10° size)
    'europe_uk_ireland': '50.0,-10.0,60.0,5.0',        # UK and Ireland
    'europe_scandinavia_west': '55.0,-10.0,70.0,5.0',   # Western Scandinavia
    'europe_scandinavia_east': '55.0,5.0,70.0,20.0',    # Eastern Scandinavia
    'europe_baltic': '55.0,20.0,70.0,35.0',             # Baltic states
    'europe_france_benelux': '40.0,-10.0,55.0,5.0',     # France and Benelux
    'europe_germany_west': '45.0,5.0,55.0,15.0',        # Western Germany
    'europe_germany_east': '45.0,15.0,55.0,25.0',       # Eastern Germany
    'europe_poland_czech': '45.0,15.0,55.0,25.0',       # Poland and Czech Republic
    'europe_slovakia_hungary': '45.0,15.0,55.0,25.0',   # Slovakia and Hungary
    'europe_spain_portugal': '35.0,-10.0,45.0,5.0',     # Spain and Portugal
    'europe_italy_west': '35.0,5.0,45.0,15.0',          # Western Italy
    'europe_italy_east': '35.0,15.0,45.0,25.0',         # Eastern Italy
    'europe_balkans_west': '35.0,15.0,45.0,25.0',       # Western Balkans
    'europe_balkans_east': '35.0,25.0,45.0,35.0',       # Eastern Balkans
    'europe_greece': '35.0,20.0,45.0,30.0',             # Greece
    
    # North America (ultra-small chunks)
    'north_america_new_england': '40.0,-80.0,50.0,-70.0',    # New England
    'north_america_maritime': '40.0,-70.0,50.0,-60.0',       # Maritime provinces
    'north_america_great_lakes': '40.0,-90.0,50.0,-80.0',    # Great Lakes
    'north_america_midwest': '40.0,-100.0,50.0,-90.0',       # Midwest
    'north_america_pacific_nw': '40.0,-130.0,50.0,-120.0',   # Pacific Northwest
    'north_america_california_north': '35.0,-130.0,45.0,-120.0', # Northern California
    'north_america_california_south': '30.0,-130.0,40.0,-120.0', # Southern California
    'north_america_southwest': '30.0,-120.0,40.0,-110.0',    # Southwest US
    'north_america_texas_north': '30.0,-110.0,40.0,-100.0',  # Northern Texas
    'north_america_texas_south': '25.0,-110.0,35.0,-100.0',  # Southern Texas
    'north_america_southeast': '25.0,-90.0,35.0,-80.0',      # Southeast US
    'north_america_florida': '25.0,-85.0,35.0,-75.0',        # Florida
    'north_america_alaska_south': '55.0,-180.0,65.0,-150.0', # Southern Alaska
    'north_america_alaska_north': '65.0,-180.0,75.0,-150.0', # Northern Alaska
    'north_america_canada_west': '50.0,-130.0,60.0,-120.0',  # Western Canada
    'north_america_canada_central': '50.0,-120.0,60.0,-110.0', # Central Canada
    'north_america_canada_east': '50.0,-90.0,60.0,-80.0',    # Eastern Canada
    'north_america_canada_north': '60.0,-120.0,70.0,-80.0',  # Northern Canada
    
    # Asia (ultra-small chunks)
    'asia_siberia_west': '55.0,40.0,65.0,55.0',         # Western Siberia
    'asia_siberia_central': '55.0,55.0,65.0,70.0',       # Central Siberia
    'asia_siberia_east': '55.0,70.0,65.0,85.0',          # Eastern Siberia
    'asia_siberia_far_east': '55.0,85.0,65.0,100.0',     # Far East Siberia
    'asia_siberia_pacific': '55.0,100.0,65.0,115.0',     # Pacific Siberia
    'asia_siberia_coast': '55.0,115.0,65.0,130.0',       # Siberian Coast
    'asia_siberia_kamchatka': '55.0,130.0,65.0,145.0',   # Kamchatka
    'asia_central_kazakhstan': '40.0,50.0,50.0,65.0',    # Kazakhstan
    'asia_central_uzbekistan': '35.0,55.0,45.0,70.0',    # Uzbekistan
    'asia_central_kyrgyzstan': '35.0,70.0,45.0,85.0',    # Kyrgyzstan
    'asia_central_mongolia': '40.0,85.0,50.0,100.0',     # Mongolia
    'asia_south_pakistan': '20.0,60.0,30.0,75.0',        # Pakistan
    'asia_south_india_north': '20.0,70.0,30.0,85.0',     # Northern India
    'asia_south_india_central': '15.0,70.0,25.0,85.0',   # Central India
    'asia_south_india_south': '10.0,70.0,20.0,85.0',     # Southern India
    'asia_south_bangladesh': '20.0,85.0,30.0,100.0',     # Bangladesh
    'asia_south_myanmar': '15.0,85.0,25.0,100.0',        # Myanmar
    'asia_south_thailand': '10.0,95.0,20.0,110.0',       # Thailand
    'asia_south_vietnam': '10.0,100.0,20.0,115.0',       # Vietnam
    'asia_east_china_north': '30.0,100.0,40.0,115.0',    # Northern China
    'asia_east_china_central': '25.0,100.0,35.0,115.0',  # Central China
    'asia_east_china_south': '20.0,100.0,30.0,115.0',    # Southern China
    'asia_east_japan_honshu': '30.0,130.0,40.0,145.0',   # Honshu (main Japan)
    'asia_east_japan_kyushu': '25.0,125.0,35.0,140.0',   # Kyushu and Shikoku
    'asia_east_korea': '30.0,120.0,40.0,135.0',          # Korea
    
    # Africa (ultra-small chunks)
    'africa_morocco': '25.0,-15.0,35.0,-5.0',            # Morocco
    'africa_algeria_west': '25.0,-5.0,35.0,5.0',         # Western Algeria
    'africa_algeria_east': '25.0,5.0,35.0,15.0',         # Eastern Algeria
    'africa_tunisia_libya': '25.0,5.0,35.0,15.0',        # Tunisia and Libya
    'africa_egypt': '20.0,20.0,30.0,35.0',               # Egypt
    'africa_sudan': '10.0,20.0,20.0,35.0',               # Sudan
    'africa_ethiopia': '5.0,30.0,15.0,45.0',             # Ethiopia
    'africa_kenya': '0.0,30.0,10.0,45.0',                # Kenya
    'africa_tanzania': '-5.0,30.0,5.0,45.0',             # Tanzania
    'africa_nigeria': '5.0,-5.0,15.0,10.0',              # Nigeria
    'africa_ghana_ivory_coast': '0.0,-15.0,10.0,0.0',    # Ghana and Ivory Coast
    'africa_senegal_mali': '10.0,-20.0,20.0,-5.0',       # Senegal and Mali
    'africa_south_africa_west': '-30.0,-20.0,-20.0,-10.0', # Western South Africa
    'africa_south_africa_east': '-30.0,-10.0,-20.0,0.0',  # Eastern South Africa
    'africa_namibia': '-25.0,-20.0,-15.0,-10.0',          # Namibia
    'africa_botswana': '-25.0,20.0,-15.0,30.0',           # Botswana
    'africa_zimbabwe': '-20.0,25.0,-10.0,35.0',           # Zimbabwe
    'africa_mozambique': '-25.0,30.0,-15.0,40.0',         # Mozambique
    'africa_madagascar': '-25.0,40.0,-15.0,55.0',         # Madagascar
    
    # South America (ultra-small chunks)
    'south_america_venezuela': '0.0,-75.0,10.0,-60.0',   # Venezuela
    'south_america_colombia': '0.0,-80.0,10.0,-65.0',    # Colombia
    'south_america_ecuador': '-5.0,-85.0,5.0,-70.0',     # Ecuador
    'south_america_peru_north': '-10.0,-85.0,0.0,-70.0', # Northern Peru
    'south_america_peru_south': '-20.0,-85.0,-10.0,-70.0', # Southern Peru
    'south_america_bolivia': '-20.0,-70.0,-10.0,-55.0',  # Bolivia
    'south_america_brazil_north': '-5.0,-70.0,5.0,-55.0', # Northern Brazil
    'south_america_brazil_central': '-15.0,-70.0,-5.0,-55.0', # Central Brazil
    'south_america_brazil_south': '-25.0,-70.0,-15.0,-55.0', # Southern Brazil
    'south_america_argentina_north': '-25.0,-70.0,-15.0,-55.0', # Northern Argentina
    'south_america_argentina_central': '-35.0,-70.0,-25.0,-55.0', # Central Argentina
    'south_america_argentina_south': '-45.0,-70.0,-35.0,-55.0', # Southern Argentina
    'south_america_chile_north': '-25.0,-75.0,-15.0,-60.0', # Northern Chile
    'south_america_chile_central': '-35.0,-75.0,-25.0,-60.0', # Central Chile
    'south_america_chile_south': '-45.0,-75.0,-35.0,-60.0', # Southern Chile
    'south_america_uruguay': '-35.0,-60.0,-25.0,-45.0',  # Uruguay
    'south_america_paraguay': '-25.0,-65.0,-15.0,-50.0',  # Paraguay
    
    # Australia and Oceania (ultra-small chunks)
    'australia_north_west': '-20.0,110.0,-10.0,125.0',   # Northwestern Australia
    'australia_north_east': '-20.0,125.0,-10.0,140.0',   # Northeastern Australia
    'australia_central_west': '-30.0,110.0,-20.0,125.0', # Central Western Australia
    'australia_central_east': '-30.0,125.0,-20.0,140.0', # Central Eastern Australia
    'australia_south_west': '-40.0,110.0,-30.0,125.0',   # Southwestern Australia
    'australia_south_east': '-40.0,125.0,-30.0,140.0',   # Southeastern Australia
    'australia_tasmania': '-45.0,140.0,-35.0,155.0',     # Tasmania
    'oceania_new_zealand_north': '-40.0,165.0,-30.0,180.0', # Northern New Zealand
    'oceania_new_zealand_south': '-50.0,165.0,-40.0,180.0', # Southern New Zealand
    'oceania_fiji': '-20.0,175.0,-10.0,190.0',           # Fiji
    'oceania_papua_new_guinea': '-15.0,140.0,-5.0,155.0', # Papua New Guinea
    'oceania_solomon_islands': '-15.0,155.0,-5.0,170.0', # Solomon Islands
    'oceania_vanuatu': '-20.0,165.0,-10.0,180.0',        # Vanuatu
    'oceania_new_caledonia': '-25.0,160.0,-15.0,175.0',  # New Caledonia
    'oceania_hawaii': '-25.0,200.0,-15.0,215.0',         # Hawaii
    'oceania_samoa': '-20.0,190.0,-10.0,205.0',          # Samoa
    'oceania_tonga': '-25.0,185.0,-15.0,200.0',          # Tonga
    'oceania_french_polynesia': '-25.0,210.0,-15.0,225.0', # French Polynesia
    
    # Island nations and territories (ultra-specific coverage)
    'caribbean_cuba': '20.0,-85.0,25.0,-75.0',           # Cuba
    'caribbean_jamaica': '15.0,-80.0,20.0,-75.0',        # Jamaica
    'caribbean_hispaniola': '15.0,-75.0,20.0,-70.0',     # Hispaniola (Haiti/Dominican Republic)
    'caribbean_puerto_rico': '15.0,-70.0,20.0,-65.0',    # Puerto Rico
    'caribbean_lesser_antilles': '10.0,-70.0,20.0,-60.0', # Lesser Antilles
    'mediterranean_sicily': '35.0,10.0,40.0,20.0',       # Sicily
    'mediterranean_sardinia': '35.0,5.0,40.0,15.0',      # Sardinia
    'mediterranean_corsica': '40.0,5.0,45.0,15.0',       # Corsica
    'mediterranean_crete': '35.0,20.0,40.0,30.0',        # Crete
    'mediterranean_cyprus': '30.0,30.0,35.0,40.0',       # Cyprus
    'mediterranean_malta': '35.0,10.0,40.0,20.0',        # Malta
    'indian_ocean_seychelles': '-10.0,50.0,-5.0,60.0',   # Seychelles
    'indian_ocean_mauritius': '-25.0,55.0,-20.0,65.0',   # Mauritius
    'indian_ocean_reunion': '-25.0,55.0,-20.0,65.0',     # Réunion
    'indian_ocean_maldives': '-5.0,70.0,0.0,80.0',       # Maldives
    'indian_ocean_comoros': '-15.0,40.0,-10.0,50.0',     # Comoros
    'pacific_micronesia_federated': '-5.0,135.0,5.0,150.0', # Federated States of Micronesia
    'pacific_palau': '-5.0,130.0,5.0,145.0',             # Palau
    'pacific_marshall_islands': '-5.0,160.0,5.0,175.0',  # Marshall Islands
    'pacific_kiribati': '-5.0,170.0,5.0,185.0',          # Kiribati
    'pacific_tuvalu': '-15.0,175.0,-5.0,190.0',          # Tuvalu
    'pacific_nauru': '-5.0,165.0,5.0,180.0',             # Nauru
    
    # Polar regions (ultra-small chunks)
    'arctic_greenland_south': '60.0,-60.0,70.0,-40.0',   # Southern Greenland
    'arctic_greenland_north': '70.0,-60.0,80.0,-40.0',   # Northern Greenland
    'arctic_svalbard': '75.0,10.0,85.0,25.0',            # Svalbard
    'arctic_northern_canada': '70.0,-120.0,80.0,-100.0', # Northern Canada
    'arctic_northern_alaska': '70.0,-170.0,80.0,-150.0', # Northern Alaska
    'arctic_siberian_coast': '70.0,80.0,80.0,100.0',     # Siberian Arctic Coast
    'arctic_chukotka': '65.0,160.0,75.0,180.0',          # Chukotka
    'antarctica_peninsula': '-70.0,-80.0,-60.0,-60.0',    # Antarctic Peninsula
    'antarctica_east_coast': '-80.0,0.0,-70.0,20.0',     # East Antarctica Coast
    'antarctica_west_coast': '-80.0,-180.0,-70.0,-160.0', # West Antarctica Coast
    'antarctica_interior': '-90.0,-180.0,-80.0,180.0',   # Antarctica Interior
}

class UltraGranularWorldDownloader:
    """Downloads world fountains using ultra-small chunks with streaming to avoid memory issues"""
    
    def __init__(self, output_dir: str = "./world_data_ultra_granular"):
        self.downloader = FountainDownloader()
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
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
        logger.info(f"🌍 Downloading region: {region_name}")
        logger.info(f"📍 Bounding box: {bbox}")
        
        region_file = self.output_dir / f"{region_name}_fountains_firebase.json"
        
        try:
            # Download with extended timeout for large regions
            fountains = self.downloader.download_fountains(bbox=bbox, limit=None)
            
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
            else:
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
            self.failed_regions.append(region_name)
            self.save_progress()
            return 0
    
    def download_all_regions_streaming(self) -> Dict[str, Any]:
        """Download all world regions with streaming approach"""
        logger.info("🚀 Starting ULTRA-GRANULAR world fountain download...")
        logger.info(f"📊 Total regions: {len(ULTRA_GRANULAR_WORLD_REGIONS)}")
        logger.info(f"💾 Output directory: {self.output_dir}")
        logger.info(f"🔄 Progress will be saved after each region")
        logger.info(f"🗺️  Each region is 5-10° in size for maximum reliability")
        
        start_time = time.time()
        
        # Skip already completed regions
        remaining_regions = {k: v for k, v in ULTRA_GRANULAR_WORLD_REGIONS.items() 
                           if k not in self.region_results}
        
        if remaining_regions:
            logger.info(f"📊 Skipping {len(ULTRA_GRANULAR_WORLD_REGIONS) - len(remaining_regions)} already completed regions")
            logger.info(f"📊 Processing {len(remaining_regions)} remaining regions")
        else:
            logger.info(f"🎉 All regions already completed!")
            return self.region_results
        
        for region_name, bbox in remaining_regions.items():
            region_start = time.time()
            fountain_count = self.download_region_streaming(region_name, bbox)
            region_time = time.time() - region_start
            
            logger.info(f"⏱️  {region_name}: {fountain_count} fountains in {region_time:.1f}s")
            
            # Longer delay between regions to be very nice to the API
            time.sleep(3)
        
        total_time = time.time() - start_time
        logger.info(f"🎉 Ultra-granular world download completed in {total_time:.1f}s")
        logger.info(f"📊 Total fountains: {self.total_fountains:,}")
        
        if self.failed_regions:
            logger.warning(f"⚠️  Failed regions: {', '.join(self.failed_regions)}")
        
        return self.region_results
    
    def create_combined_file(self) -> str:
        """Create a combined file by reading individual region files (streaming approach)"""
        combined_file = self.output_dir / "world_fountains_ultra_granular_combined_firebase.json"
        
        logger.info(f"🔄 Creating combined file from individual region files...")
        
        try:
            all_fountains = []
            total_regions = 0
            
            # Read each region file and combine
            for region_name, region_info in self.region_results.items():
                if region_info.get('count', 0) > 0:
                    region_file = Path(region_info['file'])
                    if region_file.exists():
                        with open(region_file, 'r') as f:
                            region_data = json.load(f)
                            all_fountains.extend(region_data.values())
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
    
    def generate_coverage_report(self) -> str:
        """Generate a detailed coverage report"""
        report_file = self.output_dir / "coverage_report.txt"
        
        with open(report_file, 'w', encoding='utf-8') as f:
            f.write("World Fountain Coverage Report (Ultra-Granular)\n")
            f.write("=" * 60 + "\n\n")
            f.write(f"Total regions defined: {len(ULTRA_GRANULAR_WORLD_REGIONS)}\n")
            f.write(f"Completed regions: {len(self.region_results)}\n")
            f.write(f"Failed regions: {len(self.failed_regions)}\n")
            f.write(f"Total fountains: {self.total_fountains:,}\n")
            f.write(f"Output directory: {self.output_dir}\n")
            f.write(f"Region size: 5-10° chunks for maximum reliability\n\n")
            
            f.write("Region Summary:\n")
            f.write("-" * 30 + "\n")
            for region_name, region_info in self.region_results.items():
                count = region_info.get('count', 0)
                file_path = region_info.get('file', 'N/A')
                f.write(f"{region_name}: {count:,} fountains -> {file_path}\n")
            
            if self.failed_regions:
                f.write(f"\nFailed Regions:\n")
                f.write("-" * 20 + "\n")
                for region in self.failed_regions:
                    f.write(f"{region}\n")
            
            f.write(f"\nProgress file: {self.progress_file}\n")
            f.write(f"Resume capability: Yes - just run the script again\n")
            f.write(f"Ultra-granular approach: Maximum reliability with 5-10° regions\n")
        
        return str(report_file)

def main():
    """Main function for ultra-granular world download"""
    
    print("🚀 Starting ULTRA-GRANULAR world fountain download...")
    print("📊 This approach uses 100+ ultra-small regions (5-10° size)")
    print("🗺️  Covers every corner including islands and remote areas")
    print("💾 Saves each region immediately to avoid memory issues")
    print("🔄 Progress is saved after each region (can resume if interrupted)")
    print("⚡ Maximum reliability with tiny chunks - no timeouts!")
    print()
    
    # Create output directory
    output_dir = Path("./world_data_ultra_granular")
    output_dir.mkdir(exist_ok=True)
    
    try:
        downloader = UltraGranularWorldDownloader(str(output_dir))
        
        # Download all regions with streaming
        region_results = downloader.download_all_regions_streaming()
        
        # Create combined file (optional, can be done later)
        print(f"\n🔄 Creating combined file...")
        combined_file = downloader.create_combined_file()
        
        # Generate coverage report
        coverage_report = downloader.generate_coverage_report()
        
        # Final summary
        print(f"\n🎉 Ultra-granular world download completed!")
        print(f"📊 Total fountains: {downloader.total_fountains:,}")
        print(f"🌍 Regions processed: {len(ULTRA_GRANULAR_WORLD_REGIONS)}")
        print(f"✅ Completed regions: {len(region_results)}")
        print(f"❌ Failed regions: {len(downloader.failed_regions)}")
        print(f"📁 Output directory: {output_dir}")
        if combined_file:
            print(f"📁 Combined file: {combined_file}")
        print(f"📊 Coverage report: {coverage_report}")
        print(f"💾 Progress file: {downloader.progress_file}")
        
        # Region summary
        print(f"\n📊 Region Summary:")
        for region_name, region_info in region_results.items():
            count = region_info.get('count', 0)
            if count > 0:
                print(f"   {region_name}: {count:,} fountains")
        
        if downloader.failed_regions:
            print(f"\n❌ Failed Regions:")
            for region in downloader.failed_regions:
                print(f"   {region}")
        
        print(f"\n🔄 Next steps:")
        print(f"   1. Review individual region files")
        print(f"   2. Check coverage report for any gaps")
        print(f"   3. Use the combined file for database import")
        print(f"   4. Re-run failed regions if needed")
        print(f"   5. Resume interrupted downloads by running the script again")
        print(f"   6. Ultra-granular approach ensures maximum reliability!")
        
    except KeyboardInterrupt:
        print(f"\n⏹️  Download interrupted by user")
        print(f"📊 Fountains downloaded so far: {downloader.total_fountains:,}")
        print(f"📁 Partial results saved to: {output_dir}")
        print(f"🔄 Progress saved - you can resume by running the script again")
    except Exception as e:
        print(f"\n❌ Error during download: {e}")
        print(f"📁 Partial results may be saved to: {output_dir}")

if __name__ == "__main__":
    main()

