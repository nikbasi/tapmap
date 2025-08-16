#!/bin/bash

echo "========================================"
echo "Setting up Python Virtual Environment"
echo "========================================"
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

# Verify Python version is 3.12+
PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | awk '{print $2}')
echo "Found Python version: $PYTHON_VERSION"
echo

echo "Python found. Creating virtual environment..."
echo

# Create virtual environment
$PYTHON_CMD -m venv .venv
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create virtual environment"
    exit 1
fi

echo "Virtual environment created successfully!"
echo

# Activate virtual environment
echo "Activating virtual environment..."
source .venv/bin/activate

# Upgrade pip
echo "Upgrading pip..."
$PYTHON_CMD -m pip install --upgrade pip

# Install requirements
echo "Installing required packages..."
pip install -r requirements.txt
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install requirements"
    exit 1
fi

echo
echo "========================================"
echo "Setup Complete! 🎉"
echo "========================================"
echo
echo "Your virtual environment is ready!"
echo
echo "To activate it manually:"
echo "  source .venv/bin/activate"
echo
echo "To run the fountain downloader:"
echo "  python download_fountains.py"
echo "  python download_italy_fountains.py"
echo
echo "To deactivate when done:"
echo "  deactivate"
echo
