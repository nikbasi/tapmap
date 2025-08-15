@echo off
echo ========================================
echo 🇮🇹 Running Italy Fountain Downloader
echo ========================================
echo.

REM Check if virtual environment exists
if not exist ".venv" (
    echo ERROR: Virtual environment not found!
    echo Please run setup_venv.bat first.
    pause
    exit /b 1
)

REM Activate virtual environment
echo Activating virtual environment...
call .venv\Scripts\activate.bat

REM Check if activation was successful
if not defined VIRTUAL_ENV (
    echo ERROR: Failed to activate virtual environment
    pause
    exit /b 1
)

echo Virtual environment activated successfully!
echo.

REM Run the Italy fountain downloader
echo 🚰 Starting Italy fountain download...
echo ⏳ This may take several minutes...
echo.

python download_italy_fountains.py

echo.
echo Download complete! Check the 'data' folder for results.
echo.

REM Deactivate virtual environment
deactivate

pause
