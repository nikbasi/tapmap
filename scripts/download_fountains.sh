#!/bin/bash

echo "========================================"
echo "Drinking Water Fountain Downloader"
echo "========================================"
echo

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    if ! command -v python &> /dev/null; then
        echo "ERROR: Python is not installed"
        echo "Please install Python 3.7+ from https://python.org"
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
echo "Starting fountain download..."
echo

# Run the downloader with default settings
$PYTHON_CMD download_fountains.py

echo
echo "Download complete! Check the 'data' folder for results."
echo
