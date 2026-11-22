@echo off
rem Allow computers on the same office network to open the program (port 8090). Run as administrator.
net session >nul 2>&1
if errorlevel 1 (
  echo Right-click this file and choose "Run as administrator".
  pause
  exit /b 1
)
powershell -NoProfile -Command "Remove-NetFirewallRule -DisplayName Reports 8090 -ErrorAction SilentlyContinue; New-NetFirewallRule -DisplayName Reports 8090 -Direction Inbound -Protocol TCP -LocalPort 8090 -Action Allow -Profile Any -RemoteAddress LocalSubnet | Out-Null"
echo Done. Other computers on this network can now open the program.
pause
