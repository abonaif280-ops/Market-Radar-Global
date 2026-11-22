@echo off
rem Save a copy of the data (database + attachments) in the "backups" folder.
cd /d "%~dp0"
"%~dp0python\python.exe" "%~dp0run_reports.py" --backup
pause
