import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  Position? _lastKnownPosition;
  bool _isLoading = false;
  String? _error;
  bool _hasLocationPermission = false;
  bool _isLocationServiceEnabled = false;

  // Getters
  Position? get currentPosition => _currentPosition;
  Position? get lastKnownPosition => _lastKnownPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLocationPermission => _hasLocationPermission;
  bool get isLocationServiceEnabled => _isLocationServiceEnabled;

  LocationProvider() {
    _initializeLocation();
  }

  // Initialize location services
  Future<void> _initializeLocation() async {
    try {
      _setLoading(true);
      _clearError();

      // Check if location services are enabled
      _isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!_isLocationServiceEnabled) {
        _setError('Location services are disabled');
        _setLoading(false);
        return;
      }

      // Check location permission
      await _checkLocationPermission();

      // Get last known position if available
      if (_hasLocationPermission) {
        await _getLastKnownPosition();
      }

      _setLoading(false);
    } catch (e) {
      _setError('Failed to initialize location: $e');
      _setLoading(false);
    }
  }

  // Check location permission
  Future<void> _checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _hasLocationPermission = false;
        _setError('Location permission denied');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _hasLocationPermission = false;
        _setError('Location permission permanently denied');
        return;
      }

      _hasLocationPermission = true;
      _clearError();
    } catch (e) {
      _hasLocationPermission = false;
      _setError('Failed to check location permission: $e');
    }
  }

  // Request location permission
  Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      
      if (status.isGranted) {
        _hasLocationPermission = true;
        _clearError();
        notifyListeners();
        return true;
      } else {
        _hasLocationPermission = false;
        _setError('Location permission not granted');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _setError('Failed to request location permission: $e');
      return false;
    }
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      if (!_hasLocationPermission) {
        final granted = await requestLocationPermission();
        if (!granted) return null;
      }

      _setLoading(true);
      _clearError();

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _currentPosition = position;
      _lastKnownPosition = position;
      _setLoading(false);
      
      notifyListeners();
      return position;
    } catch (e) {
      _setError('Failed to get current location: $e');
      _setLoading(false);
      return null;
    }
  }

  // Get last known position
  Future<Position?> _getLastKnownPosition() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        _lastKnownPosition = position;
        _currentPosition = position;
        notifyListeners();
      }
      return position;
    } catch (e) {
      // Last known position might not be available, which is not an error
      return null;
    }
  }

  // Get location with specific accuracy
  Future<Position?> getLocationWithAccuracy(LocationAccuracy accuracy) async {
    try {
      if (!_hasLocationPermission) {
        final granted = await requestLocationPermission();
        if (!granted) return null;
      }

      _setLoading(true);
      _clearError();

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: const Duration(seconds: 15),
      );

      _currentPosition = position;
      _lastKnownPosition = position;
      _setLoading(false);
      
      notifyListeners();
      return position;
    } catch (e) {
      _setError('Failed to get location with specified accuracy: $e');
      _setLoading(false);
      return null;
    }
  }

  // Calculate distance between two positions
  double calculateDistance(Position position1, Position position2) {
    return Geolocator.distanceBetween(
      position1.latitude,
      position1.longitude,
      position2.latitude,
      position2.longitude,
    );
  }

  // Calculate bearing between two positions
  double calculateBearing(Position position1, Position position2) {
    return Geolocator.bearingBetween(
      position1.latitude,
      position1.longitude,
      position2.latitude,
      position2.longitude,
    );
  }

  // Check if location is within radius
  bool isLocationWithinRadius(
    Position center,
    Position location,
    double radiusMeters,
  ) {
    final distance = calculateDistance(center, location);
    return distance <= radiusMeters;
  }

  // Get formatted address from coordinates
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
      }
      return 'Lat: ${latitude.toStringAsFixed(6)}, Lon: ${longitude.toStringAsFixed(6)}';
    } catch (e) {
      _setError('Failed to get address: $e');
      return null;
    }
  }

  // Get coordinates from address
  Future<({double latitude, double longitude})?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        return (latitude: location.latitude, longitude: location.longitude);
      }
      _setError('Address not found');
      return null;
    } catch (e) {
      _setError('Failed to get coordinates from address: $e');
      return null;
    }
  }

  // Start location updates
  Stream<Position>? startLocationUpdates({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // meters
  }) {
    if (!_hasLocationPermission) return null;

    try {
      return Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
        ),
      );
    } catch (e) {
      _setError('Failed to start location updates: $e');
      return null;
    }
  }

  // Check if location services are enabled
  Future<bool> checkLocationServices() async {
    try {
      _isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      notifyListeners();
      return _isLocationServiceEnabled;
    } catch (e) {
      _setError('Failed to check location services: $e');
      return false;
    }
  }

  // Open location settings
  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      _setError('Failed to open location settings: $e');
    }
  }

  // Open app settings
  Future<void> openAppSettingsPage() async {
    try {
      await openAppSettings();
    } catch (e) {
      _setError('Failed to open app settings: $e');
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

  // Refresh location data
  Future<void> refresh() async {
    await _initializeLocation();
  }
}
