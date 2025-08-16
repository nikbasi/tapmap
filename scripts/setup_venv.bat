@echo off
echo ========================================
echo Setting up Python Virtual Environment
echo ========================================
echo.

REM Check if Python 3.12 is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.12 from https://python.org
    pause
    exit /b 1
)

REM Verify Python version is 3.12+
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo Found Python version: %PYTHON_VERSION%
echo.

echo Python found. Creating virtual environment...
echo.

REM Create virtual environment
python -m venv .venv
if errorlevel 1 (
    echo ERROR: Failed to create virtual environment
    pause
    exit /b 1
)

echo Virtual environment created successfully!
echo.

REM Activate virtual environment
echo Activating virtual environment...
call .venv\Scripts\activate.bat

REM Upgrade pip
echo Upgrading pip...
python -m pip install --upgrade pip

REM Install requirements
echo Installing required packages...
pip install -r requirements.txt
if errorlevel 1 (
    echo ERROR: Failed to install requirements
    pause
    exit /b 1
)

echo.
echo ========================================
echo Setup Complete! 🎉
echo ========================================
echo.
echo Your virtual environment is ready!
echo.
echo To activate it manually:
echo   .venv\Scripts\activate.bat
echo.
echo To run the fountain downloader:
echo   python download_fountains.py
echo   python download_italy_fountains.py
echo.
echo To deactivate when done:
echo   deactivate
echo.
pause
