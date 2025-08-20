@echo off
echo ========================================
echo Ultra-Granular World Fountain Downloader
echo ========================================
echo.
echo This will download fountains from the entire world
echo using 100+ ultra-small regions (5-10° size).
echo.
echo KEY FEATURES:
echo   - Complete global coverage including islands
echo   - Ultra-granular approach - NO MEMORY ISSUES
echo   - Progress saved after each region
echo   - Can resume if interrupted
echo   - Each region saved immediately to file
echo   - Maximum reliability with tiny chunks
echo.
echo This approach ensures complete coverage including:
echo   - All major continents
echo   - Islands and remote territories
echo   - Polar regions
echo   - Ocean nations
echo   - Every square kilometer of Earth
echo.
echo Are you sure you want to continue? (Y/N)
set /p choice=
if /i "%choice%"=="Y" (
    echo.
    echo Starting ultra-granular world fountain download...
    echo Activating virtual environment...
    call .venv\Scripts\activate.bat
    
    echo.
    echo Running ultra-granular world download...
    echo This will take several hours and process 100+ regions...
    echo Progress is saved after each region - you can interrupt and resume!
    echo Each region is only 5-10° in size for maximum reliability!
    python download_world_fountains_ultra_granular.py
    
    echo.
    echo Ultra-granular world fountain download completed!
) else (
    echo.
    echo Download cancelled.
    echo Consider using regional downloads instead:
    echo   python download_fountains.py --region italy
    echo   python download_fountains.py --region france
    echo   python download_fountains.py --region germany
)
echo.
pause

