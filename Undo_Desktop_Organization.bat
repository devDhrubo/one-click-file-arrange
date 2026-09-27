@echo off
title Reverting Desktop Organization...
echo ========================================================
echo        Undo Desktop File Organization
echo ========================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command "& { & '%~dp0organizer.ps1' -TargetDirectory ([Environment]::GetFolderPath('Desktop')) -Undo }"

echo.
echo ========================================================
echo Press any key to close this window...
pause >nul
