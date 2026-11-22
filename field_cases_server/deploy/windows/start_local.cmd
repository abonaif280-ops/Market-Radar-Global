@echo off
rem Local mode: one click, data stays in the "data" folder next to this file.
cd /d "%~dp0"
chcp 65001 >nul
"%~dp0python\python.exe" "%~dp0run_local.py"
if errorlevel 1 pause
