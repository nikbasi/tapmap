import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:water_fountain_finder/providers/auth_provider.dart';
import 'package:water_fountain_finder/screens/home_screen.dart';
import 'package:water_fountain_finder/utils/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Find Water Anywhere',
      description: 'Discover drinkable water fountains, taps, and refill stations near you, no matter where you are in the world.',
      icon: Icons.location_on,
      color: AppColors.primary,
    ),
    OnboardingPage(
      title: 'Stay Hydrated',
      description: 'Never worry about finding clean drinking water again. Our community helps you locate the nearest water source.',
      icon: Icons.water_drop,
      color: AppColors.fountainBlue,
    ),
    OnboardingPage(
      title: 'Contribute & Validate',
      description: 'Help others by adding new water spots and validating existing ones. Build a better world together.',
      icon: Icons.people,
      color: AppColors.waterBlue,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                child: TextButton(
                  onPressed: _skipToEnd,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Page indicators and navigation
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: page.color,
            ),
          ),

          const SizedBox(height: AppSizes.paddingXL),

          // Title
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSizes.paddingM),

          // Description
          Text(
            page.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index ? AppColors.primary : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSizes.paddingL),

          // Navigation buttons
          if (_currentPage < _pages.length - 1) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _skipToEnd,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingM),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.paddingM),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    child: const Text(
                      'Next',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Final page with authentication options
            _buildAuthenticationOptions(),
          ],

          const SizedBox(height: AppSizes.paddingM),
        ],
      ),
    );
  }

  Widget _buildAuthenticationOptions() {
    final authProvider = Provider.of<AuthProvider>(context);

    return Column(
      children: [
        // Continue as guest button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _continueAsGuest(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingM),
              side: const BorderSide(color: AppColors.primary),
            ),
            child: const Text(
              AppStrings.continueAsGuest,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSizes.paddingM),

        // Or divider
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
              child: Text(
                'or',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ],
        ),

        const SizedBox(height: AppSizes.paddingM),

        // Google sign in (use built-in icon to avoid missing asset 404s on web)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: authProvider.isLoading ? null : () => _signInWithGoogle(),
            icon: const Icon(
              Icons.g_mobiledata,
              size: 24,
              color: Colors.red,
            ),
            label: Text(
              authProvider.isLoading ? 'Signing in...' : 'Continue with Google',
              style: const TextStyle(fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingM),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),

        const SizedBox(height: AppSizes.paddingM),

        // Apple sign in (iOS only)
        if (Theme.of(context).platform == TargetPlatform.iOS)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: authProvider.isLoading ? null : () => _signInWithApple(),
              icon: const Icon(
                Icons.apple,
                size: 24,
                color: Colors.black,
              ),
              label: Text(
                authProvider.isLoading ? 'Signing in...' : 'Continue with Apple',
                style: const TextStyle(fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingM),
                side: BorderSide(color: Colors.grey.shade300),
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
          ),

        // Error message
        if (authProvider.error != null) ...[
          const SizedBox(height: AppSizes.paddingM),
          Text(
            authProvider.error!,
            style: const TextStyle(
              color: AppColors.error,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  void _continueAsGuest() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  Future<void> _signInWithGoogle() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle();
    
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  Future<void> _signInWithApple() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithApple();
    
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
