@echo off
echo Syncing Justin's Photography Website...
powershell.exe -ExecutionPolicy Bypass -File "sync-website.ps1"
echo.
echo Sync Complete! You can close this window now.
pause
