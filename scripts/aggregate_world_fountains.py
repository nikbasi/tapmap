#!/usr/bin/env python3
"""
World Fountain Data Aggregator
Aggregates all downloaded world fountain data from individual region files
into one combined file for easy processing and database import.

This script reads all the individual region JSON files from the ultra-granular
download and combines them into a single, comprehensive dataset.
"""

import json
import logging
import time
from pathlib import Path
from typing import Dict, List, Any, Optional
from collections import defaultdict

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class WorldFountainAggregator:
    """Aggregates world fountain data from individual region files"""
    
    def __init__(self, data_dir: str = "./world_data_ultra_granular"):
        self.data_dir = Path(data_dir)
        self.region_files = []
        self.aggregated_data = {}
        self.stats = {
            'total_regions': 0,
            'successful_regions': 0,
            'failed_regions': 0,
            'total_fountains': 0,
            'duplicate_ids': 0,
            'processing_time': 0
        }
        
    def scan_region_files(self) -> List[Path]:
        """Scan for all region fountain files"""
        logger.info(f"🔍 Scanning for region files in {self.data_dir}")
        
        if not self.data_dir.exists():
            logger.error(f"❌ Data directory {self.data_dir} does not exist")
            return []
        
        # Look for files ending with _fountains_firebase.json
        pattern = "*_fountains_firebase.json"
        region_files = list(self.data_dir.glob(pattern))
        
        # Also check for any other JSON files that might contain fountain data
        json_files = list(self.data_dir.glob("*.json"))
        
        logger.info(f"📁 Found {len(region_files)} region files with pattern {pattern}")
        logger.info(f"📁 Found {len(json_files)} total JSON files")
        
        # Filter out non-region files (like progress files, coverage reports)
        filtered_files = []
        for file in region_files:
            if not any(exclude in file.name.lower() for exclude in ['progress', 'coverage', 'combined', 'aggregated']):
                filtered_files.append(file)
        
        logger.info(f"📁 Filtered to {len(filtered_files)} valid region files")
        self.region_files = filtered_files
        return filtered_files
    
    def load_region_data(self, file_path: Path) -> Optional[Dict[str, Any]]:
        """Load data from a single region file"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            if isinstance(data, dict):
                # Firebase format: {"id": fountain_data, ...}
                return data
            elif isinstance(data, list):
                # Array format: [fountain_data, ...]
                return {str(i): fountain for i, fountain in enumerate(data)}
            else:
                logger.warning(f"⚠️  Unexpected data format in {file_path.name}")
                return None
                
        except json.JSONDecodeError as e:
            logger.error(f"❌ JSON decode error in {file_path.name}: {e}")
            return None
        except Exception as e:
            logger.error(f"❌ Error reading {file_path.name}: {e}")
            return None
    
    def aggregate_data(self) -> Dict[str, Any]:
        """Aggregate all region data into one dataset"""
        logger.info("🔄 Starting data aggregation...")
        
        if not self.region_files:
            logger.error("❌ No region files found. Run scan_region_files() first.")
            return {}
        
        start_time = time.time()
        all_fountains = {}
        seen_ids = set()
        
        for file_path in self.region_files:
            region_name = file_path.stem.replace('_fountains_firebase', '')
            logger.info(f"📖 Processing {region_name}...")
            
            region_data = self.load_region_data(file_path)
            if not region_data:
                self.stats['failed_regions'] += 1
                continue
            
            fountain_count = len(region_data)
            logger.info(f"📊 {region_name}: {fountain_count} fountains")
            
            # Merge fountains, handling potential ID conflicts
            for fountain_id, fountain_data in region_data.items():
                if fountain_id in seen_ids:
                    # Handle duplicate IDs by appending region suffix
                    new_id = f"{fountain_id}_{region_name}"
                    logger.debug(f"🔄 Duplicate ID {fountain_id} -> {new_id}")
                    self.stats['duplicate_ids'] += 1
                    all_fountains[new_id] = fountain_data
                else:
                    all_fountains[fountain_id] = fountain_data
                    seen_ids.add(fountain_id)
            
            self.stats['successful_regions'] += 1
            self.stats['total_fountains'] = len(all_fountains)
        
        self.stats['total_regions'] = len(self.region_files)
        self.stats['processing_time'] = time.time() - start_time
        
        self.aggregated_data = all_fountains
        logger.info(f"✅ Aggregation completed: {len(all_fountains)} total fountains")
        
        return all_fountains
    
    def save_aggregated_data(self, output_file: str = None) -> str:
        """Save aggregated data to file"""
        if not self.aggregated_data:
            logger.error("❌ No aggregated data to save. Run aggregate_data() first.")
            return ""
        
        if output_file is None:
            timestamp = time.strftime("%Y%m%d_%H%M%S")
            output_file = self.data_dir / f"world_fountains_aggregated_{timestamp}.json"
        else:
            output_file = Path(output_file)
        
        logger.info(f"💾 Saving aggregated data to {output_file}")
        
        try:
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(self.aggregated_data, f, indent=2, ensure_ascii=False)
            
            logger.info(f"✅ Aggregated data saved: {len(self.aggregated_data)} fountains")
            return str(output_file)
            
        except Exception as e:
            logger.error(f"❌ Error saving aggregated data: {e}")
            return ""
    
    def generate_summary_report(self) -> str:
        """Generate a summary report of the aggregation"""
        report_file = self.data_dir / "aggregation_summary.txt"
        
        with open(report_file, 'w', encoding='utf-8') as f:
            f.write("World Fountain Data Aggregation Summary\n")
            f.write("=" * 50 + "\n\n")
            f.write(f"Timestamp: {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"Data directory: {self.data_dir}\n\n")
            
            f.write("Statistics:\n")
            f.write("-" * 20 + "\n")
            f.write(f"Total regions scanned: {self.stats['total_regions']}\n")
            f.write(f"Successful regions: {self.stats['successful_regions']}\n")
            f.write(f"Failed regions: {self.stats['failed_regions']}\n")
            f.write(f"Total fountains: {self.stats['total_fountains']:,}\n")
            f.write(f"Duplicate IDs handled: {self.stats['duplicate_ids']}\n")
            f.write(f"Processing time: {self.stats['processing_time']:.2f} seconds\n\n")
            
            f.write("Region Files Processed:\n")
            f.write("-" * 30 + "\n")
            for file_path in self.region_files:
                if file_path.exists():
                    file_size = file_path.stat().st_size / (1024 * 1024)  # MB
                    f.write(f"{file_path.name}: {file_size:.2f} MB\n")
            
            f.write(f"\nOutput: Aggregated data saved to combined file\n")
            f.write(f"Format: Firebase-compatible JSON with unique IDs\n")
            f.write(f"Ready for: Database import, app processing, analysis\n")
        
        return str(report_file)
    
    def validate_data_integrity(self) -> Dict[str, Any]:
        """Validate the aggregated data for common issues"""
        logger.info("🔍 Validating data integrity...")
        
        validation_results = {
            'total_fountains': len(self.aggregated_data),
            'missing_coordinates': 0,
            'invalid_coordinates': 0,
            'missing_names': 0,
            'empty_descriptions': 0,
            'issues_found': []
        }
        
        for fountain_id, fountain_data in self.aggregated_data.items():
            # Check for missing coordinates
            if 'location' not in fountain_data:
                validation_results['missing_coordinates'] += 1
                validation_results['issues_found'].append(f"{fountain_id}: Missing location")
                continue
            
            location = fountain_data['location']
            if not isinstance(location, dict) or 'lat' not in location or 'lng' not in location:
                validation_results['missing_coordinates'] += 1
                validation_results['issues_found'].append(f"{fountain_id}: Invalid location format")
                continue
            
            # Check coordinate validity
            try:
                lat = float(location['lat'])
                lng = float(location['lng'])
                if not (-90 <= lat <= 90) or not (-180 <= lng <= 180):
                    validation_results['invalid_coordinates'] += 1
                    validation_results['issues_found'].append(f"{fountain_id}: Coordinates out of range ({lat}, {lng})")
            except (ValueError, TypeError):
                validation_results['invalid_coordinates'] += 1
                validation_results['issues_found'].append(f"{fountain_id}: Non-numeric coordinates")
            
            # Check for missing names
            if 'name' not in fountain_data or not fountain_data['name']:
                validation_results['missing_names'] += 1
            
            # Check for empty descriptions
            if 'description' in fountain_data and not fountain_data['description']:
                validation_results['empty_descriptions'] += 1
        
        logger.info(f"✅ Validation completed:")
        logger.info(f"   - Missing coordinates: {validation_results['missing_coordinates']}")
        logger.info(f"   - Invalid coordinates: {validation_results['invalid_coordinates']}")
        logger.info(f"   - Missing names: {validation_results['missing_names']}")
        logger.info(f"   - Empty descriptions: {validation_results['empty_descriptions']}")
        
        return validation_results

def main():
    """Main function for world fountain aggregation"""
    
    print("🌍 World Fountain Data Aggregator")
    print("=" * 40)
    print("This script combines all downloaded region files into one dataset")
    print()
    
    # Create aggregator
    aggregator = WorldFountainAggregator()
    
    try:
        # Scan for region files
        region_files = aggregator.scan_region_files()
        if not region_files:
            print("❌ No region files found. Make sure you've downloaded some data first.")
            print("💡 Run: python download_world_fountains_ultra_granular.py")
            return
        
        print(f"📁 Found {len(region_files)} region files to process")
        print()
        
        # Aggregate data
        print("🔄 Aggregating data from all regions...")
        aggregated_data = aggregator.aggregate_data()
        
        if not aggregated_data:
            print("❌ No data was aggregated. Check the logs for errors.")
            return
        
        print(f"✅ Successfully aggregated {len(aggregated_data):,} fountains")
        print()
        
        # Save aggregated data
        print("💾 Saving aggregated data...")
        output_file = aggregator.save_aggregated_data()
        
        if output_file:
            print(f"📁 Aggregated data saved to: {output_file}")
        else:
            print("❌ Failed to save aggregated data")
            return
        
        # Generate summary report
        print("📊 Generating summary report...")
        summary_file = aggregator.generate_summary_report()
        print(f"📁 Summary report: {summary_file}")
        
        # Validate data integrity
        print("🔍 Validating data integrity...")
        validation_results = aggregator.validate_data_integrity()
        
        # Final summary
        print()
        print("🎉 Aggregation completed successfully!")
        print(f"📊 Total fountains: {len(aggregated_data):,}")
        print(f"🌍 Regions processed: {aggregator.stats['successful_regions']}")
        print(f"⏱️  Processing time: {aggregator.stats['processing_time']:.2f}s")
        print(f"📁 Output file: {output_file}")
        print(f"📊 Summary report: {summary_file}")
        
        if validation_results['issues_found']:
            print(f"⚠️  Issues found: {len(validation_results['issues_found'])}")
            print("   Check the summary report for details")
        
        print()
        print("🔄 Next steps:")
        print("   1. Review the aggregated data file")
        print("   2. Check the summary report for any issues")
        print("   3. Use the aggregated file for database import")
        print("   4. Process the data in your Flutter app")
        
    except KeyboardInterrupt:
        print(f"\n⏹️  Aggregation interrupted by user")
        print(f"📊 Fountains processed so far: {len(aggregator.aggregated_data):,}")
    except Exception as e:
        print(f"\n❌ Error during aggregation: {e}")
        logger.exception("Aggregation failed")

if __name__ == "__main__":
    main()

