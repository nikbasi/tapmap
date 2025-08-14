import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:water_fountain_finder/models/user.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = kIsWeb ? FirebaseAuth.instance : FirebaseAuth.instance;
  final FirebaseFirestore _firestore = kIsWeb ? FirebaseFirestore.instance : FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = kIsWeb ? GoogleSignIn() : GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  UserModel? _userModel;
  UserModel? get userModel => _userModel;
  bool get isAuthenticated => currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool _isLoading = false;
  String? _error;

  AuthProvider() {
    if (!kIsWeb) {
      // Only listen to auth state changes on mobile platforms
      _auth.authStateChanges().listen(_onAuthStateChanged);
    }
  }

  void _onAuthStateChanged(User? user) async {
    if (user != null) {
      await _loadUserData(user.uid);
    } else {
      _userModel = null;
    }
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromFirestore(doc);
      } else {
        // Create new user document if it doesn't exist
        await _createUserDocument(uid);
      }
    } catch (e) {
      _error = 'Failed to load user data: $e';
      notifyListeners();
    }
  }

  Future<void> _createUserDocument(String uid) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userData = UserModel(
          id: uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoURL: user.photoURL,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          favoriteFountainIds: [],
          contributedFountainIds: [],
          validatedFountainIds: [],
        );

        await _firestore.collection('users').doc(uid).set(userData.toFirestore());
        _userModel = userData;
      }
    } catch (e) {
      _error = 'Failed to create user document: $e';
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Google sign-in failed: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    try {
      _setLoading(true);
      _clearError();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      await _auth.signInWithCredential(oauthCredential);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Apple sign-in failed: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Email sign-in failed: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> createUserWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      _setLoading(true);
      _clearError();

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Account creation failed: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      _userModel = null;
      _setLoading(false);
    } catch (e) {
      _setError('Sign-out failed: $e');
      _setLoading(false);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await _auth.sendPasswordResetEmail(email: email);
      _setLoading(false);
    } catch (e) {
      _setError('Password reset failed: $e');
      _setLoading(false);
    }
  }

  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    try {
      _setLoading(true);
      _clearError();

      if (displayName != null) {
        await currentUser?.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await currentUser?.updatePhotoURL(photoURL);
      }

      // Update Firestore document
      if (_userModel != null) {
        final updatedUser = _userModel!.copyWith(
          displayName: displayName ?? _userModel!.displayName,
          photoURL: photoURL ?? _userModel!.photoURL,
        );
        
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'displayName': updatedUser.displayName,
          'photoURL': updatedUser.photoURL,
        });
        
        _userModel = updatedUser;
      }

      _setLoading(false);
    } catch (e) {
      _setError('Profile update failed: $e');
      _setLoading(false);
    }
  }

  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      if (_userModel != null && currentUser != null) {
        final updatedUser = _userModel!;
        for (final entry in preferences.entries) {
          updatedUser.updatePreference(entry.key, entry.value);
        }
        
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'preferences': updatedUser.preferences,
        });
        
        _userModel = updatedUser;
        notifyListeners();
      }
    } catch (e) {
      _setError('Preferences update failed: $e');
      notifyListeners();
    }
  }

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

  void clearError() {
    _clearError();
  }
}
