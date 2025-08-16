# 🚰 Italian Fountains Import Setup Guide

This guide will help you import the 77,159 Italian fountains into your Firebase database so you can test them in your app.

## 📋 Prerequisites

✅ **Completed:**
- Python 3.12 virtual environment created
- Italian fountains data downloaded (77,159 fountains)
- Firebase project configured in Flutter app
- Import scripts created

🔄 **Next Steps:**
- Get Firebase service account key
- Import fountains to database
- Test in your app

## 🔑 Step 1: Get Firebase Service Account Key

1. **Go to Firebase Console**: https://console.firebase.google.com/project/tapmap-7b2f2

2. **Navigate to Project Settings**:
   - Click the gear icon ⚙️ next to "Project Overview"
   - Select "Project settings"

3. **Go to Service Accounts tab**:
   - Click on "Service accounts" tab
   - Click "Generate new private key" button

4. **Download the JSON file**:
   - Save it as `firebase-service-account.json` in your `scripts/` folder
   - **⚠️ Keep this file secure and never commit it to version control**

## 🚀 Step 2: Test Import with Small Batch

First, let's test with just a few fountains to make sure everything works:

```bash
# Navigate to scripts directory
cd scripts

# Test import with 5 fountains
.venv\Scripts\python.exe import_with_service_account.py --key-file firebase-service-account.json --limit 5
```

This will:
- Import only 5 fountains for testing
- Verify the import was successful
- Check if you can see them in Firebase Console

## 📊 Step 3: Import All Fountains

Once the test is successful, import all fountains:

```bash
# Import all 77,159 fountains
.venv\Scripts\python.exe import_with_service_account.py --key-file firebase-service-account.json
```

**Estimated time**: 10-15 minutes (depending on your internet connection)

**Cost impact**: 
- **Writes**: 77,159 writes = ~$0.14 (well within free tier)
- **Storage**: ~50-100 MB (well within free tier)

## 🔍 Step 4: Verify Import

1. **Check Firebase Console**:
   - Go to Firestore Database
   - Look for the `fountains` collection
   - You should see ~77,000 documents

2. **Check import verification**:
   - The script will automatically verify the import
   - Look for "✅ Import verification successful" message

## 📱 Step 5: Test in Your App

1. **Run your Flutter app**:
   ```bash
   cd ..  # Go back to project root
   flutter run
   ```

2. **Check the map**:
   - You should see Italian fountains displayed
   - Zoom to Italy to see the density

3. **Test search functionality**:
   - Search for "fountain" or "Italy"
   - Should return many results

## 🛠️ Troubleshooting

### "Service account key not found"
- Make sure you downloaded the JSON file from Firebase Console
- Check the file path in your command

### "Permission denied"
- Make sure your service account has Firestore write permissions
- Check Firebase security rules

### "Import failed"
- Check the logs for specific error messages
- Verify your internet connection
- Try with smaller batch size: `--batch-size 50`

### "No fountains showing in app"
- Check if the app is properly connected to Firebase
- Verify the collection name is `fountains`
- Check app logs for Firebase connection errors

## 📈 Monitoring & Costs

### Free Tier Limits (per day):
- **Writes**: 20,000 (you'll use ~77,000 total)
- **Reads**: 50,000
- **Storage**: 1 GB

### Cost Breakdown:
- **Import**: ~$0.14 (one-time)
- **Daily reads**: Free for first 50,000
- **Storage**: Free for first 1 GB

### Recommendations:
- Start with test import (5 fountains)
- Monitor Firebase Console usage
- Consider implementing pagination in your app

## 🎯 Next Steps After Import

1. **Test app performance** with large dataset
2. **Implement search optimization** if needed
3. **Add data validation** for user-submitted fountains
4. **Set up regular data updates** from OpenStreetMap

## 📞 Support

If you encounter issues:
1. Check the script logs for error messages
2. Verify Firebase Console settings
3. Check your internet connection
4. Try with smaller batches first

---

**Happy importing! 🎉** Your app will soon have 77,000+ Italian fountains to explore!
