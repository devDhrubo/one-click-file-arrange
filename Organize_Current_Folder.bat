@echo off
title Organizing Current Folder...
echo ========================================================
echo        Folder File Organizer - Instant 1-Click
echo ========================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command "& { & '%~dp0organizer.ps1' -TargetDirectory '%CD%' }"

echo.
echo ========================================================
echo Press any key to close this window...
pause >nul
