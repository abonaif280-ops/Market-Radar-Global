<#
  تثبيت "الحالات الميدانية" على Windows Server دون إنترنت.
  يُشغَّل من PowerShell بصلاحية مدير (Run as Administrator) من داخل المجلد المستخرج:
    powershell -ExecutionPolicy Bypass -File .\install.ps1 -Port 8080
  ما يفعله:
    1. ينسخ البرنامج إلى C:\FieldCases (أو -InstallDir)
    2. ينشئ config.ini من النموذج (أول مرة فقط) ويقصر قراءته على المدراء وSYSTEM
    3. يفتح المنفذ في جدار حماية Windows للشبكة الداخلية
    4. يسجل مهمة تشغيل تلقائي عند بدء السيرفر
#>
param(
  [string]$InstallDir = "C:\FieldCases",
  [int]$Port = 8080
)
$ErrorActionPreference = "Stop"
$source = $PSScriptRoot

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
  throw "شغّل PowerShell كمدير (Run as Administrator)"
}

Write-Host "1) نسخ الملفات إلى $InstallDir"
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
# الإعدادات والبيانات الموجودة لا تُستبدل عند التحديث.
robocopy $source $InstallDir /E /XF config.ini /XD data /NFL /NDL /NJH /NJS | Out-Null
if ($LASTEXITCODE -ge 8) { throw "فشل نسخ الملفات" }

$config = Join-Path $InstallDir "config.ini"
if (-not (Test-Path $config)) {
  Copy-Item (Join-Path $InstallDir "config.example.ini") $config
  (Get-Content $config -Encoding UTF8) -replace '^port = .*', "port = $Port" |
    Set-Content $config -Encoding UTF8
  Write-Host "2) أُنشئ config.ini — اكتب رابط قاعدة البيانات فيه ثم شغّل الخطوات التالية"
}
# config.ini فيه كلمة مرور قاعدة البيانات: قراءة للمدراء وSYSTEM فقط.
icacls $config /inheritance:r /grant:r "Administrators:F" "SYSTEM:F" | Out-Null

Write-Host "3) فتح المنفذ $Port في جدار الحماية (الشبكات الداخلية فقط)"
$ruleName = "FieldCases-$Port"
if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
  New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Protocol TCP -LocalPort $Port `
    -Action Allow -Profile Domain,Private | Out-Null
}

Write-Host "4) تسجيل التشغيل التلقائي عند بدء السيرفر"
$action = New-ScheduledTaskAction -Execute (Join-Path $InstallDir "start_server.cmd") -WorkingDirectory $InstallDir
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1) `
  -ExecutionTimeLimit ([TimeSpan]::Zero) -StartWhenAvailable
Register-ScheduledTask -TaskName "FieldCasesServer" -Action $action -Trigger $trigger -Settings $settings `
  -User "SYSTEM" -RunLevel Highest -Force | Out-Null

Write-Host ""
Write-Host "تم. الخطوات التالية (مرة واحدة):"
Write-Host "  - اكتب [database] url في $config"
Write-Host "  - $InstallDir\manage.cmd check-db"
Write-Host "  - $InstallDir\manage.cmd init-db"
Write-Host "  - $InstallDir\manage.cmd create-admin --username admin --full-name ""مدير النظام"""
Write-Host "  - Start-ScheduledTask -TaskName FieldCasesServer"
Write-Host "  - من جهاز آخر: http://<اسم السيرفر>:$Port"
