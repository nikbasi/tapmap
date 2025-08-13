# Water Fountain Finder App

A cross-platform mobile application that helps tourists and locals find drinkable water fountains worldwide. Users can discover water spots without login, and authenticated users can add new fountains and validate existing ones.

## 🌟 Features

- **Interactive Map**: Find water fountains, taps, and refill stations near you
- **No Login Required**: Browse and search fountains as a guest
- **User Contributions**: Add new water spots with photos and details
- **Community Validation**: Validate fountains added by other users
- **Advanced Search**: Filter by type, water quality, accessibility, and tags
- **Offline Support**: Cache data for offline viewing
- **Cross-Platform**: Works on both iOS and Android

## 🏗️ Architecture

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Firestore, Authentication, Storage)
- **Maps**: OpenStreetMap (free, open-source mapping)
- **State Management**: Provider pattern
- **Authentication**: OAuth (Google, Apple) + Email/Password

## 📱 Screenshots

*Screenshots will be added after the app is built*

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.10.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / Xcode (for mobile development)
- Firebase account
- Mapbox account

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/water_fountain_finder.git
   cd water_fountain_finder
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication, Firestore, and Storage
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the appropriate directories:
     - Android: `android/app/google-services.json`
     - iOS: `ios/Runner/GoogleService-Info.plist`

4. **Configure OpenStreetMap**
   - OpenStreetMap is pre-configured and requires no setup
   - The app uses the default OpenStreetMap tile server
   - No API keys or authentication needed

5. **Configure OAuth**
   - **Google Sign-In**: Follow [Flutter Google Sign-In setup](https://pub.dev/packages/google_sign_in)
   - **Apple Sign-In**: Follow [Sign in with Apple setup](https://pub.dev/packages/sign_in_with_apple)

6. **Run the app**
   ```bash
   flutter run
   ```

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the root directory:

```env
MAPBOX_ACCESS_TOKEN=your_mapbox_token
FIREBASE_PROJECT_ID=your_firebase_project_id
```

### Firebase Security Rules

Set up Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read all fountains
    match /fountains/{fountainId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        (request.auth.uid == resource.data.addedBy || 
         request.auth.token.admin == true);
    }
    
    // Users can read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == userId;
    }
  }
}
```

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── fountain.dart        # Fountain data model
│   └── user.dart           # User data model
├── providers/               # State management
│   ├── auth_provider.dart  # Authentication state
│   ├── fountain_provider.dart # Fountain data state
│   └── location_provider.dart # Location services state
├── screens/                 # App screens
│   ├── splash_screen.dart  # Loading screen
│   ├── onboarding_screen.dart # User onboarding
│   ├── home_screen.dart    # Main navigation
│   ├── map_screen.dart     # Map view
│   ├── search_screen.dart  # Search and filters
│   ├── add_fountain_screen.dart # Add new fountain
│   └── profile_screen.dart # User profile
├── widgets/                 # Reusable widgets
│   ├── fountain_info_card.dart # Fountain info display
│   └── fountain_list_item.dart # Fountain list item
└── utils/                   # Utilities
    └── constants.dart      # App constants
```

## 🧪 Testing

Run tests with:

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Coverage report
flutter test --coverage
```

## 📦 Building for Production

### Android

```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

### iOS

```bash
# Build for device
flutter build ios --release
```

## 🔒 Security Considerations

- All user inputs are validated and sanitized
- Firebase security rules prevent unauthorized access
- Location data is handled securely
- OAuth tokens are managed safely

## 🌍 Internationalization

The app supports multiple languages and locales. To add new languages:

1. Create localization files in `lib/l10n/`
2. Update `pubspec.yaml` with supported locales
3. Use `AppLocalizations.of(context)` for text

## 📊 Analytics and Monitoring

- Firebase Analytics for user behavior tracking
- Crashlytics for crash reporting
- Performance monitoring for app performance

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- OpenStreetMap community for free, open-source mapping
- OpenStreetMap contributors for worldwide map data

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/water_fountain_finder/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/water_fountain_finder/discussions)
- **Email**: support@waterfountainfinder.com

## 🔄 Changelog

### Version 1.0.0
- Initial release
- Basic map functionality
- Fountain search and filtering
- User authentication
- Fountain submission system

## 📈 Roadmap

### Phase 2 (Q2 2024)
- [ ] Photo upload and management
- [ ] Rating and review system
- [ ] Push notifications
- [ ] Offline map caching

### Phase 3 (Q3 2024)
- [ ] Social features
- [ ] Route planning
- [ ] Water quality reports
- [ ] Accessibility improvements

### Phase 4 (Q4 2024)
- [ ] AI-powered recommendations
- [ ] Integration with fitness apps
- [ ] Sustainability metrics
- [ ] Partner integrations

---

**Made with ❤️ for a more hydrated world**
