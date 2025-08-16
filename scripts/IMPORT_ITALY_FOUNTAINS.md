# 🇮🇹 Import Italian Fountains to Database

This guide will help you import the downloaded Italian water fountains into your Firestore database so they can be viewed in the TapMap app.

## 📋 Prerequisites

Before importing, ensure you have:

1. ✅ **Downloaded Italian fountains** using `download_italy_fountains.py`
2. ✅ **Firebase project set up** with Firestore database
3. ✅ **Python 3.7+** installed
4. ✅ **Firebase credentials** configured

## 🚀 Quick Import (Windows)

1. **Double-click** `import_italy_fountains.bat`
2. **Wait** for the import to complete (may take 5-15 minutes)
3. **Check** your Firebase console for the imported fountains

## 🚀 Quick Import (Mac/Linux)

1. **Make executable**: `chmod +x import_italy_fountains.sh`
2. **Run**: `./import_italy_fountains.sh`
3. **Wait** for completion and check Firebase console

## 🔧 Manual Import Process

### Step 1: Test the Data

First, verify that your data file is ready:

```bash
cd scripts
python test_italy_data.py
```

This will show you:
- ✅ File size and fountain count
- ✅ Data structure validation
- ✅ Sample fountain information
- ✅ Readiness for import

### Step 2: Set Up Firebase Credentials

#### Option A: Service Account (Recommended for Production)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Project Settings** → **Service Accounts**
4. Click **Generate New Private Key**
5. Download the JSON file
6. Place it in a secure location

#### Option B: Default Credentials (Local Development)

If you're running locally with Firebase CLI:

```bash
firebase login
firebase use your-project-id
```

### Step 3: Run the Import

#### With Service Account:
```bash
python import_italy_fountains.py --service-account path/to/serviceAccountKey.json
```

#### With Default Credentials:
```bash
python import_italy_fountains.py
```

#### Custom Options:
```bash
python import_italy_fountains.py \
  --data-file ./data/fountains_firebase_italy_all.json \
  --batch-size 500 \
  --service-account ./serviceAccountKey.json
```

## 📊 Import Process Details

The import script will:

1. **Load** the Italian fountains JSON file
2. **Transform** data to match your app's Fountain model
3. **Import** fountains in batches (default: 500 per batch)
4. **Verify** the import was successful
5. **Report** results and any errors

### Data Transformation

The script transforms OSM data to match your app's structure:

| OSM Field | App Field | Notes |
|-----------|-----------|-------|
| `name` | `name` | Italian names preserved |
| `location` | `location` | Converted to Firestore GeoPoint |
| `type` | `type` | Mapped to fountain/tap/refillStation |
| `waterQuality` | `waterQuality` | potable/nonPotable/unknown |
| `accessibility` | `accessibility` | public/restricted/private |
| `tags` | `tags` | OSM tags preserved |
| `osmData` | `osmData` | Original OSM metadata |

### Import Metadata

Each imported fountain includes:
- `importSource: "italy_osm"` - Identifies Italian fountains
- `importDate` - When the fountain was imported
- `addedBy: "osm_import_italy"` - Source attribution

## ⏱️ Expected Import Time

- **Small dataset** (< 1,000 fountains): 2-5 minutes
- **Medium dataset** (1,000-5,000 fountains): 5-15 minutes
- **Large dataset** (> 5,000 fountains): 15-30 minutes

## 🔍 Verification

After import, the script will verify:

1. **Count check** - At least 90% of fountains imported
2. **Database query** - Fountains are queryable by `importSource`
3. **Data integrity** - All required fields present

## 🚨 Troubleshooting

### Common Issues

#### "Firebase not initialized"
- Check your service account file path
- Ensure Firebase project is properly configured
- Verify internet connection

#### "Permission denied"
- Check Firebase security rules
- Ensure service account has write permissions
- Verify collection name is correct

#### "Import timeout"
- Reduce batch size: `--batch-size 250`
- Check internet connection stability
- Verify Firebase project limits

#### "Data transformation failed"
- Check JSON file format
- Verify required fields are present
- Look for malformed coordinates

### Debug Mode

Enable detailed logging:

```python
# In import_italy_fountains.py, change:
logging.basicConfig(level=logging.DEBUG, ...)
```

### Manual Verification

Check your Firebase console:

1. Go to **Firestore Database**
2. Look for the `fountains` collection
3. Filter by `importSource == "italy_osm"`
4. Verify fountain count matches expected

## 🎯 After Import

### 1. Test in Your App

The imported fountains should now appear in your TapMap app:

- **Map view** - Fountains displayed as markers
- **List view** - Fountains in search results
- **Filters** - Work with imported data

### 2. Update App Features

Consider adding:

- **Region filter** - Show only Italian fountains
- **Import date** - When fountains were added
- **Source attribution** - Credit OSM contributors

### 3. Monitor Usage

Track how the new data performs:

- **User engagement** with Italian fountains
- **Search patterns** in different regions
- **Data quality** feedback from users

## 🔄 Regular Updates

To keep data fresh:

1. **Schedule downloads** - Monthly or quarterly updates
2. **Incremental imports** - Only new/changed fountains
3. **Data validation** - User feedback on accuracy
4. **Source tracking** - Monitor OSM changes

## 📚 Additional Resources

- [Firebase Admin SDK Documentation](https://firebase.google.com/docs/admin)
- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices)
- [OSM Data Quality](https://wiki.openstreetmap.org/wiki/Data_quality)
- [Italian Water Infrastructure](https://en.wikipedia.org/wiki/Water_supply_and_sanitation_in_Italy)

## 🆘 Support

If you encounter issues:

1. **Check logs** for detailed error messages
2. **Verify prerequisites** are met
3. **Test with smaller dataset** first
4. **Check Firebase console** for errors
5. **Review this guide** for troubleshooting steps

---

**Happy importing! 🚰🇮🇹**

Your TapMap app will soon have thousands of Italian water fountains ready for users to discover and enjoy.


