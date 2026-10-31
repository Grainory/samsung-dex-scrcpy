@echo off
title Samsung DeX Auto Watcher
cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0dex-monitor.ps1" %*
pause
