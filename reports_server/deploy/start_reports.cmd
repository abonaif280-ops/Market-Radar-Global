@echo off
rem Start the Reports program. Keep this window open while people use it.
cd /d "%~dp0"
chcp 65001 >nul
"%~dp0python\python.exe" "%~dp0run_reports.py"
if errorlevel 1 pause
