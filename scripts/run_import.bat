@echo off
echo ========================================
echo   Italian Fountains Import Runner
echo ========================================
echo.

REM Check if data file exists
if not exist "data\fountains_firebase_italy_all.json" (
    echo ERROR: Data file not found!
    echo Please run download_italy_fountains.py first to download the data.
    echo.
    pause
    exit /b 1
)

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.7+ and try again
    echo.
    pause
    exit /b 1
)

REM Check if virtual environment exists
if not exist ".venv" (
    echo Virtual environment not found. Creating one...
    python -m venv .venv
    if errorlevel 1 (
        echo Failed to create virtual environment
        pause
        exit /b 1
    )
)

REM Activate virtual environment
echo Activating virtual environment...
call .venv\Scripts\activate.bat

REM Install required packages
echo Installing required packages...
pip install firebase-admin requests

REM Test the data first
echo.
echo Testing data format...
python test_italy_data.py

echo.
echo Data test completed. Ready to import?
echo.
set /p confirm="Press Enter to continue with import, or Ctrl+C to cancel..."

REM Run the import
echo.
echo Starting import process...
echo This may take 5-15 minutes depending on your internet connection.
echo.
python import_italy_fountains.py

echo.
echo Import completed!
echo Check your Firebase console to see the imported fountains.
echo.
pause


