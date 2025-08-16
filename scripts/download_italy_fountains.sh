#!/bin/bash

echo "========================================"
echo "🇮🇹 Italy Water Fountain Downloader"
echo "========================================"
echo
echo "This will download ALL water fountains in Italy"
echo "from OpenStreetMap and export them for Firebase."
echo
echo "Italy bounding box: 35.5,6.7,47.1,18.5"
echo "Covers: Sicily, Sardinia, Mainland, Alps"
echo

# Check if Python 3.12+ is installed
if ! command -v python3 &> /dev/null; then
    if ! command -v python &> /dev/null; then
        echo "ERROR: Python is not installed"
        echo "Please install Python 3.12+ from https://python.org"
        exit 1
    else
        PYTHON_CMD="python"
    fi
else
    PYTHON_CMD="python3"
fi

# Check if requirements are installed
echo "Checking dependencies..."
if ! $PYTHON_CMD -c "import requests" &> /dev/null; then
    echo "Installing required packages..."
    $PYTHON_CMD -m pip install -r requirements.txt
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to install requirements"
        exit 1
    fi
fi

echo
echo "🚰 Starting Italy fountain download..."
echo "⏳ This may take several minutes depending on your internet speed..."
echo

# Run the Italy downloader
$PYTHON_CMD download_italy_fountains.py

echo
echo "Download complete! Check the 'data' folder for results."
echo "Look for: fountains_firebase_italy_all.json"
echo
