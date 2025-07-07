@echo off
echo ================================
echo      DGlider Launcher
echo ================================
echo.

echo Checking Python installation...
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.6+ and try again
    pause
    exit /b 1
)

echo Python found! Launching DGlider GUI...
echo.

cd /d "%~dp0"
python gesture_gui.py

if errorlevel 1 (
    echo.
    echo ERROR: Failed to launch DGlider GUI
    echo Check that all required files are present
    pause
)
