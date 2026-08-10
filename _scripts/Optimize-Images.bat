@echo off
echo Optimizing images for Justin's Photography Website...
echo This will find any giant files and compress them for the web.
powershell.exe -ExecutionPolicy Bypass -File "Optimize-Images.ps1"
echo.
echo Process Complete! You can close this window now.
pause
