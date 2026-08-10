@echo off
REM ---------------------------------------------------------------
REM  Legacy launcher - rebuilds the photo grids only.
REM  Prefer "UPDATE WEBSITE.bat" in the folder above, which runs
REM  this plus the text update and thumbnail steps in order.
REM ---------------------------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync-website.ps1"
echo.
pause
