@echo off
echo ========================================
echo 🇮🇹 Italy Water Fountain Downloader
echo ========================================
echo.
echo This will download ALL water fountains in Italy
echo from OpenStreetMap and export them for Firebase.
echo.
echo Italy bounding box: 35.5,6.7,47.1,18.5
echo Covers: Sicily, Sardinia, Mainland, Alps
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.7+ from https://python.org
    pause
    exit /b 1
)

REM Check if requirements are installed
echo Checking dependencies...
pip show requests >nul 2>&1
if errorlevel 1 (
    echo Installing required packages...
    pip install -r requirements.txt
    if errorlevel 1 (
        echo ERROR: Failed to install requirements
        pause
        exit /b 1
    )
)

echo.
echo 🚰 Starting Italy fountain download...
echo ⏳ This may take several minutes depending on your internet speed...
echo.

REM Run the Italy downloader
python download_italy_fountains.py

echo.
echo Download complete! Check the 'data' folder for results.
echo Look for: fountains_firebase_italy_all.json
echo.
pause
