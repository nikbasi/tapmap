@echo off
echo ========================================
echo World Fountain Data Aggregator
echo ========================================
echo.
echo This script combines all downloaded world fountain data
echo from individual region files into one combined dataset.
echo.
echo PREREQUISITES:
echo   - Must have downloaded world fountains first
echo   - Run: download_world_ultra_granular.bat
echo.
echo FEATURES:
echo   - Combines all region files automatically
echo   - Handles duplicate IDs intelligently
echo   - Validates data integrity
echo   - Generates detailed summary report
echo   - Creates Firebase-ready combined JSON
echo.
echo Are you sure you want to continue? (Y/N)
set /p choice=
if /i "%choice%"=="Y" (
    echo.
    echo Starting world fountain data aggregation...
    echo Activating virtual environment...
    call .venv\Scripts\activate.bat
    
    echo.
    echo Running aggregation script...
    echo This will process all downloaded region files...
    python aggregate_world_fountains.py
    
    echo.
    echo World fountain aggregation completed!
    echo Check the output files in world_data_ultra_granular/
) else (
    echo.
    echo Aggregation cancelled.
    echo Make sure you have downloaded world fountains first:
    echo   download_world_ultra_granular.bat
)
echo.
pause

