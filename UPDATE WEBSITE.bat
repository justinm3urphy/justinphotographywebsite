@echo off
title Update Website
REM =====================================================================
REM  THE ONLY FILE YOU NEED TO RUN.
REM
REM  Does everything, in the right order:
REM    1. Applies wording changes from content.txt
REM    2. Makes thumbnails for any new photos you added
REM    3. Rebuilds all the photo grids and pages
REM    4. Checks nothing is broken, including on mobile
REM
REM  The scripts it uses live in the _scripts folder.
REM  You never need to open them.
REM =====================================================================
cd /d "%~dp0"

where powershell >nul 2>&1
if errorlevel 1 (
    echo.
    echo PowerShell was not found. This script needs Windows PowerShell.
    echo.
    pause
    exit /b 1
)

if not exist "%~dp0_scripts\Update-Website.ps1" (
    echo.
    echo Could not find _scripts\Update-Website.ps1
    echo The _scripts folder must sit next to this file.
    echo.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0_scripts\Update-Website.ps1"

if errorlevel 1 (
    echo.
    echo Something went wrong - read the messages above.
    pause
)
