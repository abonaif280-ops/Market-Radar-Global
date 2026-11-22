@echo off
rem Admin commands: manage.cmd check-db | init-db | create-admin --username X --full-name "..." | reset-password --username X
cd /d "%~dp0"
chcp 65001 >nul
"%~dp0python\python.exe" "%~dp0manage.py" %*
