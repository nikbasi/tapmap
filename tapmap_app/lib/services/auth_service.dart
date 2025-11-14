import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:3000/api';
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

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
