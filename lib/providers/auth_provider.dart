import 'package:flutter/material.dart';
import 'package:water_fountain_finder/models/user.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  UserModel? get userModel => _userModel;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    // For now, start with no authentication
    _isAuthenticated = false;
    _userModel = null;
  }

  // Mock sign in method
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // For now, just create a mock user
      _userModel = UserModel(
        id: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: email.split('@').first,
        photoURL: null,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Sign in failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Mock sign up method
  Future<bool> signUpWithEmailAndPassword(String email, String password, String displayName) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Create a mock user
      _userModel = UserModel(
        id: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: displayName,
        photoURL: null,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Sign up failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Mock sign out method
  Future<void> signOut() async {
    _setLoading(true);
    
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      _userModel = null;
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      _setError('Sign out failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Mock password reset method
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // In a real app, this would send a password reset email
      print('Password reset email would be sent to: $email');
      return true;
    } catch (e) {
      _setError('Password reset failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Mock Google sign in method
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Create a mock Google user
      _userModel = UserModel(
        id: 'google_user_${DateTime.now().millisecondsSinceEpoch}',
        email: 'google.user@example.com',
        displayName: 'Google User',
        photoURL: 'https://via.placeholder.com/150',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Google sign in failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Mock Apple sign in method
  Future<bool> signInWithApple() async {
    _setLoading(true);
    _clearError();
    
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Create a mock Apple user
      _userModel = UserModel(
        id: 'apple_user_${DateTime.now().millisecondsSinceEpoch}',
        email: 'apple.user@example.com',
        displayName: 'Apple User',
        photoURL: null,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Apple sign in failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateProfile({String? displayName, String? photoURL}) async {
    if (_userModel == null) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      _userModel = _userModel!.copyWith(
        displayName: displayName ?? _userModel!.displayName,
        photoURL: photoURL ?? _userModel!.photoURL,
      );
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Profile update failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check if user is signed in
  bool get isSignedIn => _isAuthenticated && _userModel != null;

  // Get current user ID
  String? get currentUserId => _userModel?.id;

  // Get current user email
  String? get currentUserEmail => _userModel?.email;

  // Get current user display name
  String? get currentUserDisplayName => _userModel?.displayName;

  // Get current user photo URL
  String? get currentUserPhotoURL => _userModel?.photoURL;

  // Mock createUserWithEmailAndPassword method
  Future<bool> createUserWithEmailAndPassword(String email, String password, String displayName) async {
    return await signUpWithEmailAndPassword(email, password, displayName);
  }

  // Mock currentUser getter for compatibility
  Map<String, dynamic>? get currentUser {
    if (_userModel == null) return null;
    return {
      'uid': _userModel!.id,
      'email': _userModel!.email,
      'displayName': _userModel!.displayName,
      'photoURL': _userModel!.photoURL,
    };
  }

  // Mock googleSignInAvailable getter
  bool get googleSignInAvailable => true;

  // Mock debugPrintUserData method
  void debugPrintUserData() {
    print('=== USER DATA DEBUG ===');
    print('Is Authenticated: $_isAuthenticated');
    print('User Model: $_userModel');
    if (_userModel != null) {
      print('Email: ${_userModel!.email}');
      print('Display Name: ${_userModel!.displayName}');
      print('Favorites: ${_userModel!.favoriteFountainIds}');
      print('Contributions: ${_userModel!.contributedFountainIds}');
      print('Validations: ${_userModel!.validatedFountainIds}');
      print('Contribution Score: ${_userModel!.contributionScore}');
    }
    print('=======================');
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
