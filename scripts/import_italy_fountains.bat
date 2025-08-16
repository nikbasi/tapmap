@echo off
echo ========================================
echo   Italian Fountains Database Import
echo ========================================
echo.

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.7+ and try again
    pause
    exit /b 1
)

REM Check if virtual environment exists
if not exist ".venv" (
    echo Virtual environment not found. Setting up...
    call setup_venv.bat
    if errorlevel 1 (
        echo Failed to setup virtual environment
        pause
        exit /b 1
    )
)

REM Activate virtual environment
echo Activating virtual environment...
call .venv\Scripts\activate.bat

REM Check if required packages are installed
echo Checking required packages...
python -c "import firebase_admin" >nul 2>&1
if errorlevel 1 (
    echo Installing required packages...
    pip install firebase-admin
    if errorlevel 1 (
        echo Failed to install required packages
        pause
        exit /b 1
    )
)

echo.
echo Starting Italian fountains import...
echo.

REM Run the import script
python import_italy_fountains.py

echo.
echo Import completed!
echo.
pause

