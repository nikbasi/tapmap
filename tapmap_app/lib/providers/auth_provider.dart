import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = true;
  bool _isAuthenticated = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _initialize();
  }

  /// Initialize and check authentication status
  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if token is valid
      final isValid = await _authService.isAuthenticated();
      if (isValid) {
        // Fetch current user from server
        _user = await _authService.fetchCurrentUser();
        _isAuthenticated = _user != null;
      } else {
        // Try to get user from storage as fallback
        _user = await _authService.getCurrentUser();
        _isAuthenticated = _user != null;
      }
    } catch (e) {
      _user = null;
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign up with email and password
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (result.success) {
        _user = result.user;
        _isAuthenticated = true;
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure('An error occurred: $e');
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.signIn(
        email: email,
        password: password,
      );

      if (result.success) {
        _user = result.user;
        _isAuthenticated = true;
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure('An error occurred: $e');
    }
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.signInWithGoogle();

      if (result.success) {
        _user = result.user;
        _isAuthenticated = true;
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure('An error occurred: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _user = null;
      _isAuthenticated = false;
    } catch (e) {
      // Even if sign out fails, clear local state
      _user = null;
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh user data from server
  Future<void> refreshUser() async {
    try {
      final user = await _authService.fetchCurrentUser();
      if (user != null) {
        _user = user;
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      // Silently fail - user might be logged out
    }
  }
}






