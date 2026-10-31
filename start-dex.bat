@echo off
setlocal enabledelayedexpansion
title Samsung DeX Auto-Bridge
cd /d "%~dp0"

echo ==========================================================
echo       Samsung Galaxy DeX Auto-Bridge (Scrcpy)
echo ==========================================================
echo.

:: 1. Check for adb
where adb.exe >nul 2>&1
if %errorlevel% neq 0 (
    for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\Google.PlatformTools*") do (
        if exist "%%D\*\adb.exe" set ADB_FOUND=1
        if exist "%%D\adb.exe" set ADB_FOUND=1
    )
    if not defined ADB_FOUND (
        echo [!] ADB not found. Installing Google.PlatformTools via WinGet...
        echo.
        winget install Google.PlatformTools --accept-source-agreements --accept-package-agreements
        echo.
    )
)

:: 2. Check for scrcpy
where scrcpy.exe >nul 2>&1
if %errorlevel% neq 0 (
    for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\Genymobile.scrcpy*") do (
        if exist "%%D\*\scrcpy.exe" set SCRCPY_FOUND=1
        if exist "%%D\scrcpy.exe" set SCRCPY_FOUND=1
    )
    if not defined SCRCPY_FOUND (
        echo [!] Scrcpy not found. Installing Genymobile.scrcpy via WinGet...
        echo.
        winget install Genymobile.scrcpy --accept-source-agreements --accept-package-agreements
        echo.
    )
)

:: 3. Launch PowerShell watcher engine
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0dex-monitor.ps1" %*

if %errorlevel% neq 0 (
    echo.
    echo Script ended.
    pause
)
