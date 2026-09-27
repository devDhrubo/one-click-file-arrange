@echo off
title Desktop File Organizer
cd /d "%~dp0"
start "" powershell -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0FileOrganizerGUI.ps1"
exit
