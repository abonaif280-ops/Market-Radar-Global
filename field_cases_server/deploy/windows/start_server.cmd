@echo off
rem Runs the server with the bundled Python (no Python install needed on the server).
cd /d "%~dp0"
"%~dp0python\python.exe" "%~dp0run_server.py"
