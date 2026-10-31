@echo off
title Install Samsung DeX Scrcpy Prerequisites
cd /d "%~dp0"

echo ==========================================================
echo   Samsung DeX Scrcpy - Prerequisites Installer
echo ==========================================================
echo.
echo Installing ADB (Google Platform Tools) and Scrcpy via WinGet...
echo.

winget install Google.PlatformTools --accept-source-agreements --accept-package-agreements
winget install Genymobile.scrcpy --accept-source-agreements --accept-package-agreements

echo.
echo ==========================================================
echo Installation complete! 
echo Connect your Samsung Galaxy phone and run start-dex.bat.
echo ==========================================================
pause
