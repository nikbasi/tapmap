#!/bin/bash

echo "========================================"
echo "Running Complete Data Pipeline"
echo "========================================"
echo

echo "Step 1: Activating virtual environment..."
source .venv/Scripts/activate

echo
echo "Step 2: Downloading Italian fountains..."
python download_italy_fountains.py

echo
echo "Step 3: Calculating geohashes with Dart..."
dart calculate_geohashes_dart.dart

echo
echo "Step 4: Converting to Dart data file..."
python convert_dart_geohash_json_to_dart.py

echo
echo "Step 5: Starting Flutter app..."
cd ..
flutter run --debug -d chrome

echo
echo "========================================"
echo "Data Pipeline Complete!"
echo "========================================"
