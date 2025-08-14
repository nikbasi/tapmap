# Firebase Setup Guide for Water Fountain Finder

This guide will help you set up Firebase for Android, iOS, and Web platforms.

## Prerequisites

1. **Firebase Project**: You should have already created a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. **Flutter SDK**: Ensure you have Flutter installed and configured

## Step 1: Download Configuration Files

### Android Configuration
1. In Firebase Console, go to **Project Settings** (gear icon)
2. Click **Add app** → **Android**
3. Use package name: `com.example.water_fountain_finder`
4. Download `google-services.json`
5. Place it in: `android/app/google-services.json`

### iOS Configuration
1. In Firebase Console, go to **Project Settings** (gear icon)
2. Click **Add app** → **iOS**
3. Use bundle ID: `com.example.waterFountainFinder`
4. Download `GoogleService-Info.plist`
5. Place it in: `ios/Runner/GoogleService-Info.plist`

### Web Configuration
1. In Firebase Console, go to **Project Settings** (gear icon)
2. Click **Add app** → **Web**
3. Copy the configuration object

## Step 2: Update Configuration Files

### Update `lib/firebase_options.dart`
Replace all `YOUR_*` values with actual values from your Firebase project:

```dart
// Example for Android
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyC...', // Your actual API key
  appId: '1:123456789:android:abc123', // Your actual app ID
  messagingSenderId: '123456789', // Your actual sender ID
  projectId: 'your-project-id', // Your actual project ID
  storageBucket: 'your-project-id.appspot.com', // Your actual storage bucket
);
```

### Update `web/firebase-config.js`
Replace the configuration object with your actual values:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSyC...",
  authDomain: "your-project-id.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project-id.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abc123",
  measurementId: "G-ABC123"
};
```

## Step 3: Enable Firebase Services

In your Firebase Console, enable these services:

1. **Authentication**
   - Go to **Authentication** → **Sign-in method**
   - Enable **Email/Password**
   - Enable **Google** (for Google Sign-in)
   - Enable **Apple** (for iOS)

2. **Firestore Database**
   - Go to **Firestore Database**
   - Click **Create database**
   - Choose **Start in test mode** (for development)

3. **Storage**
   - Go to **Storage**
   - Click **Get started**
   - Choose **Start in test mode** (for development)

4. **Analytics** (optional)
   - Go to **Analytics**
   - Click **Get started**

## Step 4: Set Up Security Rules

### Firestore Security Rules
Go to **Firestore Database** → **Rules** and set:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Anyone can read fountain data
    match /fountains/{fountainId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### Storage Security Rules
Go to **Storage** → **Rules** and set:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Users can upload images
    match /fountain-images/{imageId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

## Step 5: Test the Setup

1. **Clean and rebuild** your project:
   ```bash
   flutter clean
   flutter pub get
   ```

2. **For Android**:
   ```bash
   flutter run -d android
   ```

3. **For iOS**:
   ```bash
   cd ios
   pod install
   cd ..
   flutter run -d ios
   ```

4. **For Web**:
   ```bash
   flutter run -d chrome
   ```

## Troubleshooting

### Common Issues

1. **"Firebase not initialized" error**
   - Check that configuration files are in correct locations
   - Verify API keys and project IDs match

2. **Android build fails**
   - Ensure `google-services.json` is in `android/app/`
   - Check that Google Services plugin is applied

3. **iOS build fails**
   - Run `pod install` in `ios/` directory
   - Ensure `GoogleService-Info.plist` is in `ios/Runner/`

4. **Web not working**
   - Check browser console for JavaScript errors
   - Verify Firebase SDK scripts are loading

### Debug Mode

Add this to your main.dart for debugging:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (kIsWeb) {
      print('Web platform detected');
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized successfully');
    }
  } catch (e) {
    print('Firebase error: $e');
    // Continue without Firebase
  }
  
  runApp(const WaterFountainFinderApp());
}
```

## Next Steps

After successful setup:

1. Test authentication (sign in/sign up)
2. Test Firestore operations (create/read fountains)
3. Test file uploads to Storage
4. Deploy to production with proper security rules

## Support

If you encounter issues:
1. Check Firebase Console for error logs
2. Verify all configuration files are correct
3. Ensure Firebase services are enabled
4. Check Flutter and Firebase plugin versions compatibility
