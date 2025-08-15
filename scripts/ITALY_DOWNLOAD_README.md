# 🇮🇹 Italy Water Fountain Downloader

This script downloads **ALL** drinking water fountains in Italy from OpenStreetMap and exports them in Firebase-ready format for your database.

## 🗺️ Coverage Area

The script covers the entire country of Italy including:

- **Northern Italy**: Alps, Po Valley, Lombardy, Veneto, Piedmont
- **Central Italy**: Tuscany, Lazio, Umbria, Marche, Abruzzo
- **Southern Italy**: Campania, Basilicata, Puglia, Calabria
- **Islands**: Sicily, Sardinia, and smaller Mediterranean islands
- **Bounding Box**: `35.5,6.7,47.1,18.5` (south,west,north,east)

## 🚀 Quick Start

### Windows Users
1. Double-click `download_italy_fountains.bat`
2. Wait for the download to complete (may take 5-15 minutes)
3. Check the `data` folder for results

### Mac/Linux Users
1. Make the script executable: `chmod +x download_italy_fountains.sh`
2. Run: `./download_italy_fountains.sh`
3. Wait for completion and check the `data` folder

### Command Line Users
```bash
python download_italy_fountains.py
```

## 📊 Expected Results

Italy typically has **2,000-5,000+** water fountains across the country, including:

- **Traditional fountains** (fontane) in city squares
- **Drinking water taps** in parks and public spaces
- **Refill stations** in modern buildings
- **Historical fountains** with cultural significance
- **Mountain springs** and natural water sources

## 🏗️ Fountain Types You'll Get

The script automatically categorizes fountains by type:

- **Fountain**: Traditional drinking fountains
- **Tap**: Water taps and spigots
- **Refill Station**: Modern bottle filling stations

## 🏷️ Data Quality Features

Each fountain includes:

- **Location**: Precise GPS coordinates
- **Name**: Italian names when available
- **Description**: Details from OSM contributors
- **Water Quality**: Potable/non-potable/unknown
- **Accessibility**: Public/restricted/private
- **Tags**: Wheelchair access, indoor/outdoor, etc.
- **OSM Metadata**: Source tracking and timestamps

## 📁 Output Files

The script creates:

- `fountains_firebase_italy_all.json` - **Main file for Firebase import**
- `fountains_italy_all.csv` - CSV format for analysis
- `fountains_italy_all.json` - Raw data format

## 🔥 Firebase Import

### Option 1: Firebase Console
1. Go to Firestore Database in Firebase Console
2. Click "Import" 
3. Select `fountains_firebase_italy_all.json`
4. Choose collection name (e.g., "fountains")
5. Click "Import"

### Option 2: Programmatic Import
```javascript
// Using Firebase Admin SDK
const admin = require('firebase-admin');
const fountains = require('./fountains_firebase_italy_all.json');

Object.entries(fountains).forEach(([id, fountain]) => {
  admin.firestore().collection('fountains').doc(id).set(fountain);
});
```

### Option 3: Flutter/Firebase
```dart
// In your Flutter app
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> importFountains() async {
  final fountains = jsonDecode(await rootBundle.loadString('assets/fountains_firebase_italy_all.json'));
  
  for (final entry in fountains.entries) {
    await FirebaseFirestore.instance
        .collection('fountains')
        .doc(entry.key)
        .set(entry.value);
  }
}
```

## ⏱️ Download Time

- **Small cities**: 1-3 minutes
- **Large cities**: 3-8 minutes  
- **Entire Italy**: 5-15 minutes (depending on internet speed)

## 🌍 Regional Distribution

The script provides breakdowns by region:

- **Northern Italy**: Alpine and Po Valley fountains
- **Central Italy**: Tuscan and Lazio fountains  
- **Southern Italy**: Mediterranean and island fountains

## 🚨 Important Notes

### Rate Limiting
- The Overpass API has rate limits
- Italy download is within acceptable limits
- If you get errors, wait a few minutes and retry

### Data Accuracy
- All coordinates are validated
- Names are in Italian when available
- Some fountains may be unnamed (marked as "Unnamed Fountain")
- Water quality is inferred from OSM tags

### File Size
- Expected size: 2-8 MB depending on fountain count
- JSON format is optimized for Firebase
- CSV format is good for data analysis

## 🔧 Troubleshooting

### "No fountains found" error
- Check internet connection
- Verify Python and dependencies are installed
- Try running the general downloader first: `python download_fountains.py --limit 10`

### Download timeout
- Italy is a large area, be patient
- Check your internet connection speed
- Consider downloading smaller regions first

### Memory issues
- The script handles large datasets efficiently
- If you have issues, try downloading by regions instead

## 📈 Next Steps After Download

1. **Review the data** in the JSON file
2. **Import to Firebase** using one of the methods above
3. **Test in your app** to ensure fountains display correctly
4. **Download other countries** using the main downloader
5. **Set up regular updates** to keep data fresh

## 🌟 Why Italy?

Italy is an excellent choice for testing because:

- **Rich fountain culture** with thousands of historical and modern fountains
- **Good OSM coverage** with active contributors
- **Manageable size** - not too small, not too large
- **Diverse geography** - mountains, cities, islands, rural areas
- **Cultural significance** - fountains are important landmarks

## 🚰 Sample Fountain Data

Here's what a typical Italian fountain looks like in the output:

```json
{
  "osm_node_12345": {
    "id": "osm_node_12345",
    "name": "Fontana di Trevi",
    "description": "Famous Baroque fountain in Rome",
    "location": {
      "latitude": 41.9009,
      "longitude": 12.4833
    },
    "type": "fountain",
    "status": "active",
    "waterQuality": "potable",
    "accessibility": "public",
    "addedBy": "osm_import",
    "addedDate": "2024-01-15T10:30:00",
    "validations": [],
    "photos": [],
    "tags": ["wheelchair", "outdoor", "tourist"],
    "osmData": {
      "osmId": "node_12345",
      "source": "osm",
      "lastUpdated": "2024-01-15T10:30:00"
    }
  }
}
```

## 📞 Support

If you encounter issues:

1. Check the main README.md for general troubleshooting
2. Verify your Python environment and dependencies
3. Test with a smaller area first using the main downloader
4. Check the Overpass API status at https://overpass-api.de/

Happy fountain hunting! 🚰🇮🇹
