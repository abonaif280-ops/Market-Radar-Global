@echo off
rem Reset a user password (for example if the admin forgot it). Run on the server.
cd /d "%~dp0"
set /p FC_USER=Username to reset (for example admin): 
"%~dp0python\python.exe" "%~dp0manage.py" reset-password --username %FC_USER%
pause
