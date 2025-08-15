# Drinking Water Fountain Downloader

This script downloads drinking water fountains from OpenStreetMap using the Overpass API (the same system used by Overpass Turbo) and formats them for import into your Firebase database.

## Features

- Downloads all types of drinking water facilities:
  - Drinking water fountains (`amenity=drinking_water`)
  - Water taps (`amenity=water_point`)
  - Refill stations (`amenity=water_refill`)
  - Bottle filling stations (`amenity=bottle_filling`)
- Supports geographic bounding boxes for regional downloads
- Exports data in multiple formats:
  - JSON (raw data)
  - CSV (spreadsheet format)
  - Firebase JSON (ready for database import)
- Handles different OSM element types (nodes, ways, relations)
- Extracts relevant metadata and tags

## Installation

1. Install Python 3.7+ if you haven't already
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

## Usage

### Basic Usage

Download all fountains worldwide (this will be a large dataset):
```bash
python download_fountains.py
```

### Download by Geographic Region

Download fountains in a specific area using bounding box coordinates:

```bash
# New York City area (south,west,north,east)
python download_fountains.py --bbox "40.4774,-74.2591,40.9176,-73.7004"

# London area
python download_fountains.py --bbox "51.0,-0.5,51.7,0.3"

# San Francisco area
python download_fountains.py --bbox "37.6,-122.6,37.9,-122.3"
```

### Limit Results

Limit the number of results (useful for testing):
```bash
python download_fountains.py --limit 100
```

### Output Format

Choose specific output format:
```bash
# Only Firebase format
python download_fountains.py --format firebase

# Only CSV format
python download_fountains.py --format csv

# All formats (default)
python download_fountains.py --format all
```

### Custom Output Directory

Specify where to save the files:
```bash
python download_fountains.py --output-dir ./my_data
```

## Output Files

The script creates timestamped files in the output directory:

- `fountains_YYYYMMDD_HHMMSS.json` - Raw data in JSON format
- `fountains_YYYYMMDD_HHMMSS.csv` - Data in CSV format for Excel/Google Sheets
- `fountains_firebase_YYYYMMDD_HHMMSS.json` - Firebase-compatible format

## Firebase Import Format

The Firebase JSON file is structured for easy import:

```json
{
  "osm_node_12345": {
    "id": "osm_node_12345",
    "name": "Central Park Water Fountain",
    "description": "Public drinking fountain in Central Park",
    "location": {
      "latitude": 40.7829,
      "longitude": -73.9654
    },
    "type": "fountain",
    "status": "active",
    "waterQuality": "potable",
    "accessibility": "public",
    "addedBy": "osm_import",
    "addedDate": "2024-01-15T10:30:00",
    "validations": [],
    "photos": [],
    "tags": ["wheelchair", "outdoor"],
    "osmData": {
      "osmId": "node_12345",
      "source": "osm",
      "lastUpdated": "2024-01-15T10:30:00"
    }
  }
}
```

## Importing to Firebase

1. **Firebase Console Import:**
   - Go to Firestore Database in Firebase Console
   - Click "Import" and select your Firebase JSON file
   - Choose the collection (e.g., "fountains")

2. **Programmatic Import:**
   ```javascript
   // In your Firebase admin script
   const admin = require('firebase-admin');
   const fountains = require('./fountains_firebase_20240115_103000.json');
   
   Object.entries(fountains).forEach(([id, fountain]) => {
     admin.firestore().collection('fountains').doc(id).set(fountain);
   });
   ```

## Geographic Bounding Boxes

To find coordinates for a specific area:

1. **Use Google Maps:**
   - Right-click on the map
   - Select "What's here?"
   - Copy the coordinates

2. **Use OpenStreetMap:**
   - Go to openstreetmap.org
   - Right-click and select "Show address"
   - Note the coordinates

3. **Use boundingbox.klokantech.com:**
   - Draw a rectangle on the map
   - Copy the coordinates in the format: `south,west,north,east`

## Data Quality

The script automatically:
- Maps OSM amenity types to your app's fountain types
- Determines water quality from OSM tags
- Sets accessibility levels based on access restrictions
- Extracts relevant tags (wheelchair access, indoor/outdoor, etc.)
- Handles missing or incomplete data gracefully

## Rate Limiting

The Overpass API has rate limits. For large downloads:
- Use bounding boxes to limit geographic scope
- Add delays between requests if needed
- Consider running during off-peak hours

## Troubleshooting

**"No fountains downloaded" error:**
- Check your internet connection
- Verify the bounding box coordinates are valid
- Try a smaller geographic area first

**Large file sizes:**
- Use `--limit` to restrict results
- Use `--bbox` to focus on specific regions
- Use `--format firebase` to only get the format you need

**Memory issues:**
- Process data in smaller chunks
- Use streaming for very large datasets

## Contributing

Feel free to improve the script:
- Add support for more OSM tags
- Implement additional export formats
- Add data validation and cleaning
- Optimize for large datasets

## License

This script is provided as-is for educational and development purposes. Please respect OpenStreetMap's usage policies and attribution requirements.
