import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:water_fountain_finder/providers/auth_provider.dart';
import 'package:water_fountain_finder/providers/fountain_provider.dart';
import 'package:water_fountain_finder/providers/location_provider.dart';
import 'package:water_fountain_finder/screens/splash_screen.dart';
import 'package:water_fountain_finder/screens/sign_in_screen.dart';
import 'package:water_fountain_finder/screens/sign_up_screen.dart';
import 'package:water_fountain_finder/utils/constants.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;

// Global variable to track Firebase initialization status
bool isFirebaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('Initializing Firebase...');
    print('Platform: ${defaultTargetPlatform}');
    print('Is Web: $kIsWeb');
    
    if (kIsWeb) {
      print('Web platform detected, initializing Firebase for web...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.web,
      );
      print('Firebase initialized successfully for web');
      isFirebaseInitialized = true;
    } else {
      print('Native platform detected, initializing Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized successfully for ${defaultTargetPlatform}');
      isFirebaseInitialized = true;
    }
  } catch (e, stackTrace) {
    print('Firebase initialization error: $e');
    print('Stack trace: $stackTrace');
    print('Continuing without Firebase...');
    isFirebaseInitialized = false;
  }

  runApp(const WaterFountainFinderApp());
}

class WaterFountainFinderApp extends StatelessWidget {
  const WaterFountainFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FountainProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: MaterialApp(
        title: 'Water Fountain Finder',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        home: isFirebaseInitialized 
          ? const SplashScreen() 
          : _buildFirebaseErrorScreen(),
        routes: {
          '/signin': (context) => const SignInScreen(),
          '/signup': (context) => const SignUpScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  Widget _buildFirebaseErrorScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Error'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'Firebase Connection Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to connect to Firebase services. This may be due to:\n\n'
                '• Network connectivity issues\n'
                '• Firebase configuration problems\n'
                '• Service temporarily unavailable\n\n'
                'Please check your internet connection and try again.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Try to restart the app
                  // In a real app, you might want to implement a proper restart mechanism
                  print('User requested app restart');
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
