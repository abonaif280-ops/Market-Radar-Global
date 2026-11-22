@echo off
rem Runs the server with the bundled Python (no Python install needed on the server).
cd /d "%~dp0"
chcp 65001 >nul
"%~dp0python\python.exe" "%~dp0run_server.py"
