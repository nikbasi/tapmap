@echo off
echo 🚀 Updating fountains with geohash fields...
echo.

REM Check if virtual environment exists
if exist "venv\Scripts\activate.bat" (
    echo ✅ Virtual environment found, activating...
    call venv\Scripts\activate.bat
) else (
    echo ⚠️ Virtual environment not found, creating one...
    python -m venv venv
    call venv\Scripts\activate.bat
    echo 📦 Installing requirements...
    pip install -r requirements.txt
)

echo.
echo 🔄 Running geohash update script...
python update_geohash.py

echo.
echo ✅ Script completed!
pause

