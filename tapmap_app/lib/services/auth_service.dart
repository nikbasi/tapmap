import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/api_config.dart';

class AuthService {
  static const String baseUrl = ApiConfig.baseUrl;
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  
  // Configure Google Sign-In based on platform
  // For Android: serverClientId is required to get ID token
  // The Android OAuth client should be in google-services.json
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // serverClientId is the Web client ID - needed for ID token on Android
    serverClientId: '500324905447-1nicspq57p31pdom8ic4a1fa129lbceq.apps.googleusercontent.com',
    // scopes for additional permissions if needed
    scopes: ['email', 'profile'],
  );

  /// Sign up with email and password
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          if (displayName != null) 'display_name': displayName,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['token'] as String;
        final user = data['user'] as Map<String, dynamic>;

        // Store token and user data
        await _storage.write(key: _tokenKey, value: token);
        await _storage.write(key: _userKey, value: jsonEncode(user));

        return AuthResult.success(
          token: token,
          user: User.fromJson(user),
        );
      } else {
        final error = jsonDecode(response.body)['error'] as String?;
        return AuthResult.failure(error ?? 'Sign up failed');
      }
    } catch (e) {
      return AuthResult.failure('Network error: $e');
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] as String;
        final user = data['user'] as Map<String, dynamic>;

        // Store token and user data
        await _storage.write(key: _tokenKey, value: token);
        await _storage.write(key: _userKey, value: jsonEncode(user));

        return AuthResult.success(
          token: token,
          user: User.fromJson(user),
        );
      } else {
        final error = jsonDecode(response.body)['error'] as String?;
        return AuthResult.failure(error ?? 'Invalid email or password');
      }
    } catch (e) {
      return AuthResult.failure('Network error: $e');
    }
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // The user canceled the sign-in
        return AuthResult.failure('Sign in canceled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null && accessToken == null) {
        return AuthResult.failure('Failed to retrieve Google Auth Credentials. Please check your Firebase configuration.');
      }

      // Send the token to the backend
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': idToken,
          'access_token': accessToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] as String;
        final user = data['user'] as Map<String, dynamic>;

        // Store token and user data
        await _storage.write(key: _tokenKey, value: token);
        await _storage.write(key: _userKey, value: jsonEncode(user));

        return AuthResult.success(
          token: token,
          user: User.fromJson(user),
        );
      } else {
        final error = jsonDecode(response.body)['error'] as String?;
        return AuthResult.failure(error ?? 'Google sign in failed');
      }
    } catch (e) {
      // Provide more detailed error message
      final errorMessage = e.toString();
      if (errorMessage.contains('PlatformException')) {
        if (errorMessage.contains('sign_in_failed') || errorMessage.contains('SIGN_IN_REQUIRED')) {
          return AuthResult.failure('Google Sign-In failed. Please check your Firebase configuration and SHA-1 fingerprint.');
        } else if (errorMessage.contains('network_error') || errorMessage.contains('NETWORK_ERROR')) {
          return AuthResult.failure('Network error. Please check your internet connection.');
        }
      }
      return AuthResult.failure('Google sign in error: $e');
    }
  }

  /// Get current user from storage
  Future<User?> getCurrentUser() async {
    try {
      final userJson = await _storage.read(key: _userKey);
      if (userJson != null) {
        return User.fromJson(jsonDecode(userJson));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get stored token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Verify token with server
  Future<bool> verifyToken() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['valid'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get current user from server
  Future<User?> fetchCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final userJson = jsonDecode(response.body);
        final user = User.fromJson(userJson);
        
        // Update stored user data
        await _storage.write(key: _userKey, value: jsonEncode(userJson));
        
        return user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
    await _googleSignIn.signOut();
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    if (token == null) return false;
    return await verifyToken();
  }
}

/// Authentication result
class AuthResult {
  final bool success;
  final String? error;
  final String? token;
  final User? user;

  AuthResult.success({required this.token, required this.user})
      : success = true,
        error = null;

  AuthResult.failure(this.error)
      : success = false,
        token = null,
        user = null;
}

/// User model
class User {
  final int id;
  final String email;
  final String? displayName;
  final String? provider;
  final String? avatarUrl;
  final bool? emailVerified;

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.provider,
    this.avatarUrl,
    this.emailVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      provider: json['provider'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      emailVerified: json['email_verified'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'provider': provider,
      'avatar_url': avatarUrl,
      'email_verified': emailVerified,
    };
  }
}
