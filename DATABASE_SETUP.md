# 🗄️ Database Index Setup for Zoom-Based Fountain Loading

## 🚨 **Required Action**
You need to create a **composite index** in Firestore for the zoom-based fountain loading to work.

## 📋 **Step-by-Step Instructions**

### 1. **Go to Firebase Console**
- Visit: https://console.firebase.google.com/
- Select your project

### 2. **Navigate to Firestore**
- Click on "Firestore Database" in the left sidebar
- Click on "Indexes" tab

### 3. **Create Composite Index**
- Click "Create Index"
- Fill in the following:

```
Collection ID: fountains
Fields to index:
  - Field path: status, Order: Ascending
  - Field path: location.latitude, Order: Ascending  
  - Field path: location.longitude, Order: Ascending
```

**Important**: The order of fields matters! Use exactly this sequence.

### 4. **Wait for Index Creation**
- Index creation takes **2-5 minutes**
- You'll see "Building" status, then "Enabled"

## 🔍 **What This Index Does**
- **Enables geographic queries** by latitude and longitude
- **Filters by status** at database level (efficient)
- **Restricts queries to high zoom levels only** (zoom 12+)
- **Queries only the specific viewport area** (no arbitrary limits)
- **Minimizes costs** by preventing low-zoom queries

## ⚠️ **Without This Index**
- The app will use **fallback queries** (less efficient)
- **Still works** but costs more and is slower
- You'll see fallback messages in the console

## ✅ **After Index Creation**
- **Blue button will work** only at zoom level 12+ (city level)
- **Queries only the specific viewport area** (no arbitrary limits)
- **Minimal costs** - only loads fountains in the visible area
- **Better user experience** - prevents expensive low-zoom queries

---

*This index is essential for the production optimization to work properly.*
