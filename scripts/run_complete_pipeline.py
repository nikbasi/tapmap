#!/usr/bin/env python3
"""
Complete Data Pipeline Runner
This script runs the entire data pipeline from downloading Italian fountains
to starting the Flutter app.
"""

import subprocess
import sys
import os
from pathlib import Path

def run_command(command, description, cwd=None):
    """Run a command and handle errors"""
    print(f"\n{description}")
    print(f"Command: {command}")
    
    try:
        result = subprocess.run(
            command,
            shell=True,
            cwd=cwd,
            capture_output=True,
            text=True,
            check=True
        )
        print(f"SUCCESS: {description} completed successfully")
        if result.stdout:
            print(f"Output: {result.stdout}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"ERROR: {description} failed with exit code {e.returncode}")
        if e.stdout:
            print(f"stdout: {e.stdout}")
        if e.stderr:
            print(f"stderr: {e.stderr}")
        return False

def main():
    """Run the complete data pipeline"""
    print("Starting Complete Data Pipeline")
    print("=" * 50)
    
    # Get the scripts directory
    scripts_dir = Path(__file__).parent
    project_root = scripts_dir.parent
    
    # Step 1: Download Italian fountains
    print("\nStep 1: Downloading Italian fountains...")
    if not run_command("python download_italy_fountains.py", "Download Italian fountains", cwd=scripts_dir):
        print("Failed to download fountains. Stopping pipeline.")
        return False
    
    # Step 2: Calculate geohashes with Dart
    print("\nStep 2: Calculating geohashes with Dart...")
    if not run_command("dart calculate_geohashes_dart.dart", "Calculate geohashes", cwd=scripts_dir):
        print("Failed to calculate geohashes. Stopping pipeline.")
        return False
    
    # Step 3: Convert to Dart data file
    print("\nStep 3: Converting to Dart data file...")
    if not run_command("python convert_dart_geohash_json_to_dart.py", "Convert to Dart", cwd=scripts_dir):
        print("Failed to convert to Dart. Stopping pipeline.")
        return False
    
    # Step 4: Start Flutter app
    print("\nStep 4: Starting Flutter app...")
    if not run_command("flutter run --debug -d chrome", "Start Flutter app", cwd=project_root):
        print("Failed to start Flutter app.")
        return False
    
    print("\nData Pipeline Complete!")
    print("The Flutter app should now be running in Chrome.")
    return True

if __name__ == "__main__":
    success = main()
    if not success:
        sys.exit(1)
