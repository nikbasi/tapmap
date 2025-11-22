class ApiConfig {
  // DEVELOPMENT (Localhost)
  // static const String baseUrl = 'http://localhost:3000/api';
  
  // DEVELOPMENT (Android Emulator)
  // static const String baseUrl = 'http://10.0.2.2:3000/api';
  
  // PRODUCTION
  // static const String baseUrl = 'http://129.158.216.36/api';
  
  // Use --dart-define=API_URL=... to override
  // Default to production server for APK builds
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://129.158.216.36/api',
  );
}
