@echo off
title Organizing Desktop...
echo ========================================================
echo        Desktop File Organizer - Instant 1-Click
echo ========================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command "& { & '%~dp0organizer.ps1' -TargetDirectory ([Environment]::GetFolderPath('Desktop')) }"

echo.
echo ========================================================
echo Press any key to close this window...
pause >nul
