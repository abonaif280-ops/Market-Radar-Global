@echo off
rem Start the Reports program. Keep this window open while people use it.
cd /d "%~dp0"
chcp 65001 >nul
:run
"%~dp0python\python.exe" "%~dp0run_reports.py"
rem Exit code 3 = a backup was imported: start again on the new data.
if errorlevel 3 if not errorlevel 4 (set REPORTS_NO_BROWSER=1& goto run)
if errorlevel 1 pause
