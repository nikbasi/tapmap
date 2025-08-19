import 'dart:convert';
import 'dart:io';
import 'dart:math';

// Simple geohash implementation that matches dart_geohash library
class GeohashCalculator {
  static const String _base32 = "0123456789bcdefghjkmnpqrstuvwxyz";
  
  static String encode(double latitude, double longitude, {int precision = 5}) {
    double latMin = -90.0;
    double latMax = 90.0;
    double lonMin = -180.0;
    double lonMax = 180.0;
    
    String geohash = "";
    int bit = 0;
    int ch = 0;
    
    while (geohash.length < precision) {
      if (bit % 2 == 0) {
        // Even bit: bisect longitude
        final mid = (lonMin + lonMax) / 2;
        if (longitude >= mid) {
          ch |= (1 << (4 - bit % 5));
          lonMin = mid;
        } else {
          lonMax = mid;
        }
      } else {
        // Odd bit: bisect latitude
        final mid = (latMin + latMax) / 2;
        if (latitude >= mid) {
          ch |= (1 << (4 - bit % 5));
          latMin = mid;
        } else {
          latMax = mid;
        }
      }
      
      bit++;
      
      if (bit % 5 == 0) {
        geohash += _base32[ch];
        ch = 0;
      }
    }
    
    return geohash;
  }
}

void main() async {
  print('Calculating geohashes with Dart and updating JSON file...');
  
  // Input and output file paths
  final inputFile = File('italy_data_fixed/fountains_firebase_20250817_010551.json');
  final outputFile = File('italy_data_fixed/fountains_with_dart_geohashes.json');
  
  try {
    // Read the JSON file
    print('Reading JSON file...');
    final jsonString = await inputFile.readAsString();
    final Map<String, dynamic> data = json.decode(jsonString);
    
    print('JSON loaded successfully. Found ${data.length} fountain entries.');
    
    // Process each fountain entry
    print('Calculating geohashes with Dart...');
    int processedCount = 0;
    int skippedCount = 0;
    
    data.forEach((fountainId, fountainData) {
      try {
        // Extract coordinates
        double? latitude, longitude;
        
        final location = fountainData['location'];
        if (location is Map<String, dynamic>) {
          latitude = (location['latitude'] as num).toDouble();
          longitude = (location['longitude'] as num).toDouble();
        } else {
          latitude = (fountainData['latitude'] as num?)?.toDouble();
          longitude = (fountainData['longitude'] as num?)?.toDouble();
        }
        
        // Skip if no valid coordinates
        if (latitude == null || longitude == null || 
            latitude == 0.0 || longitude == 0.0) {
          skippedCount++;
          return;
        }
        
        // Calculate geohashes using Dart implementation
        final geohash5 = GeohashCalculator.encode(latitude, longitude, precision: 5);
        final geohash4 = GeohashCalculator.encode(latitude, longitude, precision: 4);
        final geohash3 = GeohashCalculator.encode(latitude, longitude, precision: 3);
        
        // Add geohash fields to the fountain data
        fountainData['geohashPrec5'] = geohash5;
        fountainData['geohashPrec4'] = geohash4;
        fountainData['geohashPrec3'] = geohash3;
        
        processedCount++;
        
        // Progress indicator
        if (processedCount % 1000 == 0) {
          print('Processed $processedCount fountains...');
        }
        
      } catch (e) {
        print('Error processing fountain $fountainId: $e');
        skippedCount++;
      }
    });
    
    // Write the updated JSON file
    print('Writing updated JSON file...');
    final updatedJsonString = json.encode(data);
    await outputFile.writeAsString(updatedJsonString);
    
    print('Successfully processed $processedCount fountains');
    print('Skipped $skippedCount fountains (invalid coordinates)');
    print('Output file: ${outputFile.path}');
    
    // File size comparison
    final inputSize = inputFile.lengthSync() / (1024 * 1024); // MB
    final outputSize = outputFile.lengthSync() / (1024 * 1024); // MB
    
    print('File sizes:');
    print('   Input:  ${inputSize.toStringAsFixed(2)} MB');
    print('   Output: ${outputSize.toStringAsFixed(2)} MB');
    print('   Added:  ${(outputSize - inputSize).toStringAsFixed(2)} MB (geohash fields)');
    
    print('Geohashes calculated with Dart implementation - ready for consistent filtering!');
    
  } catch (e) {
    print('Error processing file: $e');
    exit(1);
  }
}
