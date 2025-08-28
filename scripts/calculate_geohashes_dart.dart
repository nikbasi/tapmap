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

void main(List<String> args) async {
  // Show help if requested
  if (args.contains('--help') || args.contains('-h')) {
    print('''
Usage: dart calculate_geohashes_dart.dart [input_file] [output_file]

Arguments:
  input_file    Path to the input JSON file (default: world_data_ultra_granular/world_fountains_ultra_granular_combined_firebase.json)
  output_file   Path to the output JSON file (default: auto-generated based on input filename)

Examples:
  dart calculate_geohashes_dart.dart
  dart calculate_geohashes_dart.dart my_fountains.json
  dart calculate_geohashes_dart.dart my_fountains.json my_output.json
  dart calculate_geohashes_dart.dart --help

The script will:
  - Read the input JSON file
  - Calculate geohashes for each fountain using Dart implementation
  - Add a 'geohash' field to each fountain entry
  - Save the result to the output file
''');
    return;
  }
  
  print('Calculating geohashes with Dart and updating JSON file...');
  
  // Parse command line arguments
  String inputFilePath;
  String outputFilePath;
  
  if (args.length >= 1) {
    inputFilePath = args[0];
  } else {
    inputFilePath = 'world_data_ultra_granular/world_fountains_ultra_granular_combined_firebase.json';
  }
  
  if (args.length >= 2) {
    outputFilePath = args[1];
  } else {
    // Generate output filename based on input filename
    final inputFile = File(inputFilePath);
    final baseName = inputFile.path.split('/').last.replaceAll('.json', '');
    outputFilePath = '${inputFile.parent.path}/${baseName}_with_dart_geohashes.json';
  }
  
  // Input and output file paths
  final inputFile = File(inputFilePath);
  final outputFile = File(outputFilePath);
  
  print('Input file: ${inputFile.path}');
  print('Output file: ${outputFile.path}');
  
  // Check if input file exists
  if (!inputFile.existsSync()) {
    print('Error: Input file does not exist: ${inputFile.path}');
    print('Usage: dart calculate_geohashes_dart.dart [input_file] [output_file]');
    print('Example: dart calculate_geohashes_dart.dart my_fountains.json my_fountains_with_geohashes.json');
    print('Use --help for more information');
    exit(1);
  }
  
  try {
    // Read the JSON file
    print('Reading JSON file...');
    final jsonString = await inputFile.readAsString();
    final dynamic rawData = json.decode(jsonString);
    
    // Handle both Map and List formats
    Map<String, dynamic> data;
    bool isListFormat = false;
    
    if (rawData is Map<String, dynamic>) {
      // Original format: {"fountain_id": {...}}
      data = rawData;
      print('JSON loaded successfully. Found ${data.length} fountain entries (Map format).');
    } else if (rawData is List<dynamic>) {
      // New format: [{...}, {...}, {...}]
      isListFormat = true;
      // Convert list to map with auto-generated IDs
      data = <String, dynamic>{};
      for (int i = 0; i < rawData.length; i++) {
        final fountainData = rawData[i] as Map<String, dynamic>;
        final fountainId = fountainData['id'] ?? 'fountain_$i';
        data[fountainId] = fountainData;
      }
      print('JSON loaded successfully. Found ${data.length} fountain entries (List format, converted to Map).');
    } else {
      throw FormatException('Unsupported JSON format. Expected Map or List, got ${rawData.runtimeType}');
    }
    
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
        
        // Calculate geohash with highest precision using Dart implementation
        final geohash = GeohashCalculator.encode(latitude, longitude, precision: 12);
        
        // Add single geohash field to the fountain data
        fountainData['geohash'] = geohash;
        
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
    
    // Convert back to original format if it was a list
    dynamic outputData;
    if (isListFormat) {
      outputData = data.values.toList();
      print('Converting back to List format for output...');
    } else {
      outputData = data;
    }
    
    // Write the updated JSON file with nice formatting
    print('Writing updated JSON file with nice formatting...');
    
    // Pretty-print the JSON with proper indentation
    final encoder = JsonEncoder.withIndent('  ');
    final prettyJsonString = encoder.convert(outputData);
    await outputFile.writeAsString(prettyJsonString);
    
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
