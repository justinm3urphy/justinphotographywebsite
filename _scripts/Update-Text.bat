@echo off
REM ====================================================
REM  Double-click this to update your website text
REM  from content.txt
REM ====================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update-Text.ps1"

