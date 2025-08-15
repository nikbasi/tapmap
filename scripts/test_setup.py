#!/usr/bin/env python3
"""
Test script to verify the virtual environment setup
Run this after setting up the virtual environment to ensure everything works.
"""

import sys
import requests
from pathlib import Path

def test_python_version():
    """Test Python version"""
    print(f"🐍 Python version: {sys.version}")
    if sys.version_info < (3, 7):
        print("❌ Python 3.7+ is required")
        return False
    print("✅ Python version is compatible")
    return True

def test_requests():
    """Test requests library"""
    try:
        print("📡 Testing requests library...")
        response = requests.get("https://httpbin.org/get", timeout=10)
        if response.status_code == 200:
            print("✅ Requests library is working")
            return True
        else:
            print(f"❌ Requests test failed with status: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Requests test failed: {e}")
        return False

def test_pathlib():
    """Test pathlib library"""
    try:
        print("📁 Testing pathlib library...")
        current_dir = Path.cwd()
        print(f"✅ Current directory: {current_dir}")
        return True
    except Exception as e:
        print(f"❌ Pathlib test failed: {e}")
        return False

def test_imports():
    """Test all required imports"""
    required_modules = [
        'json', 'csv', 'datetime', 'typing', 'logging', 'dataclasses', 
        'argparse', 'pathlib', 'requests'
    ]
    
    print("📦 Testing required modules...")
    failed_imports = []
    
    for module in required_modules:
        try:
            __import__(module)
            print(f"  ✅ {module}")
        except ImportError as e:
            print(f"  ❌ {module}: {e}")
            failed_imports.append(module)
    
    if failed_imports:
        print(f"❌ Failed to import: {', '.join(failed_imports)}")
        return False
    
    print("✅ All required modules imported successfully")
    return True

def test_downloader_import():
    """Test importing the fountain downloader"""
    try:
        print("🚰 Testing fountain downloader import...")
        from download_fountains import FountainDownloader, DataExporter
        print("✅ Fountain downloader imported successfully")
        return True
    except Exception as e:
        print(f"❌ Fountain downloader import failed: {e}")
        return False

def test_directory_structure():
    """Test directory structure"""
    print("📂 Testing directory structure...")
    
    current_dir = Path.cwd()
    required_files = [
        'download_fountains.py',
        'download_italy_fountains.py',
        'requirements.txt'
    ]
    
    missing_files = []
    for file in required_files:
        if not (current_dir / file).exists():
            missing_files.append(file)
    
    if missing_files:
        print(f"❌ Missing files: {', '.join(missing_files)}")
        return False
    
    print("✅ All required files found")
    return True

def main():
    """Run all tests"""
    print("🧪 Testing Virtual Environment Setup")
    print("=" * 40)
    print()
    
    tests = [
        ("Python Version", test_python_version),
        ("Directory Structure", test_directory_structure),
        ("Required Modules", test_imports),
        ("Pathlib Library", test_pathlib),
        ("Requests Library", test_requests),
        ("Fountain Downloader", test_downloader_import),
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        print(f"🔍 {test_name}...")
        if test_func():
            passed += 1
        print()
    
    print("=" * 40)
    print(f"📊 Test Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! Your environment is ready.")
        print()
        print("🚰 You can now run:")
        print("  python download_fountains.py --limit 5")
        print("  python download_italy_fountains.py")
    else:
        print("❌ Some tests failed. Check the errors above.")
        print()
        print("💡 Try running the setup script again:")
        print("  Windows: setup_venv.bat")
        print("  Mac/Linux: ./setup_venv.sh")
    
    return passed == total

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
