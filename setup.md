# Setup Guide - Water Fountain Finder App

This guide will walk you through setting up the development environment for the Water Fountain Finder app.

## 🚀 Quick Start

### 1. Install Flutter

1. **Download Flutter SDK**
   - Visit [flutter.dev](https://flutter.dev/docs/get-started/install)
   - Download the latest stable version for your OS
   - Extract to a location (e.g., `C:\flutter` on Windows, `~/flutter` on macOS/Linux)

2. **Add Flutter to PATH**
   - **Windows**: Add `C:\flutter\bin` to your PATH environment variable
   - **macOS/Linux**: Add `~/flutter/bin` to your PATH in `~/.bash_profile` or `~/.zshrc`

3. **Verify Installation**
   ```bash
   flutter doctor
   ```
   Fix any issues reported by `flutter doctor`

### 2. Install Dependencies

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd water_fountain_finder
   ```

2. **Install Flutter packages**
   ```bash
   flutter pub get
   ```

### 3. Firebase Setup

1. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Click "Create a project"
   - Enter project name: "Water Fountain Finder"
   - Enable Google Analytics (optional)
   - Click "Create project"

2. **Enable Services**
   - **Authentication**: Go to Authentication > Sign-in method
     - Enable Google Sign-in
     - Enable Apple Sign-in (iOS only)
     - Enable Email/Password
   
   - **Firestore**: Go to Firestore Database
     - Click "Create database"
     - Choose "Start in test mode" (we'll add security rules later)
     - Select location closest to your users
   
   - **Storage**: Go to Storage
     - Click "Get started"
     - Choose "Start in test mode"
     - Select location

3. **Download Configuration Files**
   - **Android**: Click the gear icon > Project settings > General > Your apps > Android app
     - Package name: `com.example.water_fountain_finder`
     - Download `google-services.json`
     - Place in `android/app/`
   
   - **iOS**: Click the gear icon > Project settings > General > Your apps > iOS app
     - Bundle ID: `com.example.waterFountainFinder`
     - Download `GoogleService-Info.plist`
     - Place in `ios/Runner/`

### 4. Mapbox Setup

1. **Create Mapbox Account**
   - Go to [mapbox.com](https://www.mapbox.com/)
   - Sign up for a free account
   - Verify your email

2. **Get Access Token**
   - Go to Account > Access tokens
   - Copy your default public token
   - Update `lib/utils/constants.dart`:
     ```dart
     static const String mapboxAccessToken = 'YOUR_TOKEN_HERE';
     ```

### 5. Platform-Specific Setup

#### Android

1. **Install Android Studio**
   - Download from [developer.android.com](https://developer.android.com/studio)
   - Install with default settings

2. **Configure Android SDK**
   - Open Android Studio
   - Go to Tools > SDK Manager
   - Install Android SDK 33 (API level 33) or higher
   - Install Android SDK Build-Tools

3. **Create Android Virtual Device**
   - Go to Tools > AVD Manager
   - Click "Create Virtual Device"
   - Choose a phone (e.g., Pixel 4)
   - Download and select a system image (API 33 or higher)

#### iOS (macOS only)

1. **Install Xcode**
   - Download from Mac App Store
   - Install command line tools:
     ```bash
     xcode-select --install
     ```

2. **Configure iOS Simulator**
   - Open Xcode
   - Go to Window > Devices and Simulators
   - Download a simulator (iOS 14.0 or higher)

### 6. OAuth Configuration

#### Google Sign-In

1. **Enable Google Sign-In API**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Select your Firebase project
   - Go to APIs & Services > Library
   - Search for "Google Sign-In API" and enable it

2. **Configure OAuth Consent Screen**
   - Go to APIs & Services > OAuth consent screen
   - Choose "External" user type
   - Fill in required information
   - Add scopes: `email`, `profile`

3. **Create OAuth 2.0 Credentials**
   - Go to APIs & Services > Credentials
   - Click "Create credentials" > "OAuth 2.0 Client IDs"
   - Choose "Android" or "iOS"
   - Fill in package name/bundle ID
   - Download the configuration file

#### Apple Sign-In (iOS only)

1. **Enable Sign in with Apple**
   - Go to [Apple Developer](https://developer.apple.com/)
   - Go to Certificates, Identifiers & Profiles
   - Select your App ID
   - Enable "Sign in with Apple" capability

### 7. Test the Setup

1. **Run the app**
   ```bash
   flutter run
   ```

2. **Verify functionality**
   - App should launch without errors
   - Map should display (may show error without valid token)
   - Navigation between screens should work
   - Authentication should work (with proper OAuth setup)

## 🔧 Troubleshooting

### Common Issues

1. **Flutter doctor issues**
   - Install missing dependencies
   - Accept Android licenses: `flutter doctor --android-licenses`
   - Install Xcode command line tools on macOS

2. **Firebase connection errors**
   - Verify configuration files are in correct locations
   - Check Firebase project settings
   - Ensure services are enabled

3. **Mapbox errors**
   - Verify access token is correct
   - Check token permissions
   - Ensure account is verified

4. **OAuth errors**
   - Verify OAuth configuration
   - Check package names/bundle IDs match
   - Ensure APIs are enabled

### Getting Help

- Check [Flutter documentation](https://flutter.dev/docs)
- Visit [Firebase documentation](https://firebase.google.com/docs)
- Check [Mapbox documentation](https://docs.mapbox.com/)
- Open an issue on GitHub

## 📱 Next Steps

After successful setup:

1. **Customize the app**
   - Update app name and branding
   - Modify colors and themes
   - Add your own water fountain data

2. **Test on real devices**
   - Connect physical Android/iOS device
   - Test location services
   - Verify camera and photo functionality

3. **Deploy to app stores**
   - Follow Flutter deployment guides
   - Configure app signing
   - Submit to Google Play Store and App Store

## 🎯 Development Workflow

1. **Make changes** to the code
2. **Test locally** with `flutter run`
3. **Run tests** with `flutter test`
4. **Build for testing** with `flutter build`
5. **Deploy** to app stores

---

**Happy coding! 🚀**
