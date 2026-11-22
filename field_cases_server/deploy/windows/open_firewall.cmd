@echo off
rem Opens the app port in Windows Firewall for the office network (asks for admin rights once).
set PORT=8080
net session >nul 2>&1
if errorlevel 1 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
powershell -NoProfile -Command "if (-not (Get-NetFirewallRule -DisplayName 'FieldCases-%PORT%' -ErrorAction SilentlyContinue)) { New-NetFirewallRule -DisplayName 'FieldCases-%PORT%' -Direction Inbound -Protocol TCP -LocalPort %PORT% -Action Allow -Profile Any -RemoteAddress LocalSubnet | Out-Null }"
echo Port %PORT% is open for the office network.
pause
