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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Log and continue; app should still navigate to onboarding
    // ignore: avoid_print
    print('Firebase initialization error: $e');
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
        home: const SplashScreen(),
        routes: {
          '/signin': (context) => const SignInScreen(),
          '/signup': (context) => const SignUpScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
