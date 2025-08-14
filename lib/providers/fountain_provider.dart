import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:water_fountain_finder/models/fountain.dart';
import 'package:water_fountain_finder/models/user.dart';
import 'package:water_fountain_finder/providers/auth_provider.dart';

class FountainProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Fountain> _fountains = [];
  List<Fountain> _filteredFountains = [];
  Fountain? _selectedFountain;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  Map<String, dynamic> _filters = {};

  // Getters
  List<Fountain> get fountains => _fountains;
  List<Fountain> get filteredFountains => _filteredFountains;
  Fountain? get selectedFountain => _selectedFountain;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  FountainProvider() {
    _loadFountains();
  }

  // Load all fountains
  Future<void> _loadFountains() async {
    try {
      _setLoading(true);
      _clearError();

      final querySnapshot = await _firestore
          .collection('fountains')
          .where('status', isEqualTo: 'active')
          .orderBy('addedDate', descending: true)
          .get();

      _fountains = querySnapshot.docs
          .map((doc) => Fountain.fromFirestore(doc))
          .toList();

      _applyFiltersAndSearch();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load fountains: $e');
      _setLoading(false);
    }
  }

  // Load fountains near a specific location
  Future<List<Fountain>> loadFountainsNearLocation(
    double latitude,
    double longitude,
    double radiusKm,
  ) async {
    try {
      _setLoading(true);
      _clearError();

      // Calculate bounding box for the search radius
      final latDelta = radiusKm / 111.0; // 1 degree = ~111 km
      final lonDelta = radiusKm / (111.0 * cos(latitude * pi / 180));

      final querySnapshot = await _firestore
          .collection('fountains')
          .where('status', isEqualTo: 'active')
          .where('location.latitude', isGreaterThanOrEqualTo: latitude - latDelta)
          .where('location.latitude', isLessThanOrEqualTo: latitude + latDelta)
          .get();

      // Filter by longitude and calculate actual distances
      final nearbyFountains = querySnapshot.docs
          .map((doc) => Fountain.fromFirestore(doc))
          .where((fountain) {
        final distance = _calculateDistance(
          latitude,
          longitude,
          fountain.location.latitude,
          fountain.location.longitude,
        );
        return distance <= radiusKm;
      }).toList();

      // Sort by distance
      nearbyFountains.sort((a, b) {
        final distanceA = _calculateDistance(
          latitude,
          longitude,
          a.location.latitude,
          a.location.longitude,
        );
        final distanceB = _calculateDistance(
          latitude,
          longitude,
          b.location.latitude,
          b.location.longitude,
        );
        return distanceA.compareTo(distanceB);
      });

      _setLoading(false);
      return nearbyFountains;
    } catch (e) {
      _setError('Failed to load nearby fountains: $e');
      _setLoading(false);
      return [];
    }
  }

  // Add a new fountain
  Future<bool> addFountain(Fountain fountain, AuthProvider authProvider) async {
    try {
      _setLoading(true);
      _clearError();

      final currentUser = authProvider.currentUser;
      if (currentUser == null) {
        _setError('User not authenticated');
        _setLoading(false);
        return false;
      }

      final docRef = await _firestore.collection('fountains').add(fountain.toFirestore());
      
      // Update the fountain with the generated ID
      final newFountain = fountain.copyWith(id: docRef.id);
      _fountains.insert(0, newFountain);
      
      // Update user contribution
      await _updateUserContribution(currentUser.uid, docRef.id);
      
      // Refresh user data in AuthProvider
      await authProvider.refreshUserData();
      
      _applyFiltersAndSearch();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add fountain: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update an existing fountain
  Future<bool> updateFountain(Fountain fountain) async {
    try {
      _setLoading(true);
      _clearError();

      await _firestore.collection('fountains').doc(fountain.id).update(fountain.toFirestore());
      
      final index = _fountains.indexWhere((f) => f.id == fountain.id);
      if (index != -1) {
        _fountains[index] = fountain;
        _applyFiltersAndSearch();
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update fountain: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete a fountain
  Future<bool> deleteFountain(String fountainId) async {
    try {
      _setLoading(true);
      _clearError();

      await _firestore.collection('fountains').doc(fountainId).delete();
      
      _fountains.removeWhere((f) => f.id == fountainId);
      _applyFiltersAndSearch();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete fountain: $e');
      _setLoading(false);
      return false;
    }
  }

  // Validate a fountain
  Future<bool> validateFountain(String fountainId, bool isValid, String? comment, AuthProvider authProvider) async {
    try {
      _setLoading(true);
      _clearError();

      final currentUser = authProvider.currentUser;
      if (currentUser == null) {
        _setError('User not authenticated');
        _setLoading(false);
        return false;
      }

      final validation = Validation(
        userId: currentUser.uid,
        timestamp: DateTime.now(),
        isValid: isValid,
        comment: comment,
      );

      // Update fountain with validation
      await _firestore.collection('fountains').doc(fountainId).update({
        'validations': FieldValue.arrayUnion([validation.toMap()]),
      });

      // Update user document with validation
      await _updateUserValidation(currentUser.uid, fountainId);

      // Update local data
      final index = _fountains.indexWhere((f) => f.id == fountainId);
      if (index != -1) {
        final fountain = _fountains[index];
        final updatedValidations = [...fountain.validations, validation];
        _fountains[index] = fountain.copyWith(validations: updatedValidations);
        _applyFiltersAndSearch();
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to validate fountain: $e');
      _setLoading(false);
      return false;
    }
  }

  // Toggle favorite for a fountain
  Future<bool> toggleFavorite(String fountainId, AuthProvider authProvider) async {
    try {
      _setLoading(true);
      _clearError();

      final currentUser = authProvider.currentUser;
      if (currentUser == null) {
        _setError('User not authenticated');
        _setLoading(false);
        return false;
      }

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        _setError('User document not found');
        _setLoading(false);
        return false;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final favoriteFountainIds = List<String>.from(userData['favoriteFountainIds'] ?? []);
      
      bool isFavorite = favoriteFountainIds.contains(fountainId);
      
      if (isFavorite) {
        // Remove from favorites
        favoriteFountainIds.remove(fountainId);
        await _firestore.collection('users').doc(currentUser.uid).update({
          'favoriteFountainIds': favoriteFountainIds,
        });
      } else {
        // Add to favorites
        favoriteFountainIds.add(fountainId);
        await _firestore.collection('users').doc(currentUser.uid).update({
          'favoriteFountainIds': favoriteFountainIds,
        });
      }

      // Refresh user data in AuthProvider
      await authProvider.refreshUserData();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to toggle favorite: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update user contribution when adding a fountain
  Future<void> _updateUserContribution(String userId, String fountainId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'contributedFountainIds': FieldValue.arrayUnion([fountainId]),
        'contributionScore': FieldValue.increment(10),
      });
    } catch (e) {
      print('Failed to update user contribution: $e');
    }
  }

  // Update user validation
  Future<void> _updateUserValidation(String userId, String fountainId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'validatedFountainIds': FieldValue.arrayUnion([fountainId]),
        'contributionScore': FieldValue.increment(5),
      });
    } catch (e) {
      print('Failed to update user validation: $e');
    }
  }

  // Search fountains
  void searchFountains(String query) {
    _searchQuery = query;
    _applyFiltersAndSearch();
  }

  // Apply filters
  void applyFilters(Map<String, dynamic> filters) {
    _filters = filters;
    _applyFiltersAndSearch();
  }

  // Clear filters
  void clearFilters() {
    _filters.clear();
    _applyFiltersAndSearch();
  }

  // Apply filters and search
  void _applyFiltersAndSearch() {
    _filteredFountains = _fountains.where((fountain) {
      // Apply search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!fountain.name.toLowerCase().contains(query) &&
            !fountain.description.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Apply filters
      for (final entry in _filters.entries) {
        switch (entry.key) {
          case 'type':
            if (fountain.type.name != entry.value) return false;
            break;
          case 'status':
            if (fountain.status.name != entry.value) return false;
            break;
          case 'waterQuality':
            if (fountain.waterQuality.name != entry.value) return false;
            break;
          case 'accessibility':
            if (fountain.accessibility.name != entry.value) return false;
            break;
          case 'tags':
            final tags = entry.value as List<String>;
            if (!tags.any((tag) => fountain.tags.contains(tag))) return false;
            break;
          case 'minRating':
            if (fountain.rating == null || fountain.rating! < entry.value) return false;
            break;
        }
      }

      return true;
    }).toList();

    notifyListeners();
  }

  // Set selected fountain
  void selectFountain(Fountain? fountain) {
    _selectedFountain = fountain;
    notifyListeners();
  }

  // Get fountain by ID
  Fountain? getFountainById(String id) {
    try {
      return _fountains.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get fountains by user
  List<Fountain> getFountainsByUser(String userId) {
    return _fountains.where((f) => f.addedBy == userId).toList();
  }

  // Get favorite fountains for user
  List<Fountain> getFavoriteFountains(UserModel user) {
    return _fountains.where((f) => user.hasFavorited(f.id)).toList();
  }

  // Check if a fountain is favorited by current user
  bool isFavoritedByCurrentUser(String fountainId, AuthProvider authProvider) {
    final user = authProvider.userModel;
    return user?.hasFavorited(fountainId) ?? false;
  }

  // Get user's contributed fountains
  List<Fountain> getUserContributions(UserModel user) {
    return _fountains.where((f) => user.hasContributed(f.id)).toList();
  }

  // Get user's validated fountains
  List<Fountain> getUserValidations(UserModel user) {
    return _fountains.where((f) => user.hasValidated(f.id)).toList();
  }

  // Get user statistics
  Map<String, dynamic> getUserStats(UserModel user) {
    final contributions = getUserContributions(user);
    final validations = getUserValidations(user);
    final favorites = getFavoriteFountains(user);

    return {
      'totalContributions': contributions.length,
      'totalValidations': validations.length,
      'totalFavorites': favorites.length,
      'contributionScore': user.contributionScore,
      'contributionLevel': user.contributionLevel,
    };
  }

  // Refresh all data from database
  Future<void> refreshData() async {
    await _loadFountains();
    notifyListeners();
  }

  // Debug method to print current state
  void debugPrintState() {
    print('=== FOUNTAIN PROVIDER DEBUG ===');
    print('Total Fountains: ${_fountains.length}');
    print('Filtered Fountains: ${_filteredFountains.length}');
    print('Selected Fountain: ${_selectedFountain?.id ?? 'None'}');
    print('Is Loading: $_isLoading');
    print('Error: $_error');
    print('Search Query: $_searchQuery');
    print('Filters: $_filters');
    print('===============================');
  }

  // Calculate distance between two points using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
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

  // Refresh data
  Future<void> refresh() async {
    await _loadFountains();
  }
}
