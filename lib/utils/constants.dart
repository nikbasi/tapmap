import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color accent = Color(0xFFFF4081);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  
  // Water-related colors
  static const Color waterBlue = Color(0xFF81C784);
  static const Color fountainBlue = Color(0xFF64B5F6);
  static const Color tapBlue = Color(0xFF42A5F5);
}

class AppSizes {
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 48.0;
}

class AppStrings {
  static const String appName = 'Water Fountain Finder';
  static const String appDescription = 'Find drinkable water spots worldwide';
  static const String appTagline = 'Stay hydrated, anywhere in the world';
  
  // Navigation
  static const String home = 'Home';
  static const String map = 'Map';
  static const String search = 'Search';
  static const String addFountain = 'Add Fountain';
  static const String profile = 'Profile';
  
  // Authentication
  static const String signIn = 'Sign In';
  static const String signOut = 'Sign Out';
  static const String signUp = 'Sign Up';
  static const String continueAsGuest = 'Continue as Guest';
  
  // Fountain Types
  static const String fountain = 'Fountain';
  static const String tap = 'Tap';
  static const String refillStation = 'Refill Station';
  
  // Status
  static const String active = 'Active';
  static const String inactive = 'Inactive';
  static const String maintenance = 'Maintenance';
  
  // Water Quality
  static const String potable = 'Potable';
  static const String nonPotable = 'Non-Potable';
  static const String unknown = 'Unknown';
  
  // Accessibility
  static const String public = 'Public';
  static const String restricted = 'Restricted';
  static const String private = 'Private';
}

class AppConfig {
  // OpenStreetMap Configuration
  static const String osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmAttribution = '© OpenStreetMap contributors';
  
  // Firebase Configuration
  static const String firebaseProjectId = 'YOUR_FIREBASE_PROJECT_ID';
  
  // API Configuration
  static const int apiTimeoutSeconds = 30;
  static const int maxRetries = 3;
  
  // Map Configuration
  static const double defaultZoom = 15.0;
  static const double minZoom = 10.0;
  static const double maxZoom = 18.0;
  static const double searchRadiusKm = 5.0;
  
  // Cache Configuration
  static const int maxCacheSize = 100;
  static const Duration cacheExpiration = Duration(hours: 24);
}

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String map = '/map';
  static const String search = '/search';
  static const String addFountain = '/add-fountain';
  static const String fountainDetails = '/fountain-details';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String about = '/about';
}
