<#
  بناء حزمة التثبيت (تُشغَّل في CI على Windows أو أي جهاز Windows متصل بالإنترنت):
  Python مضمّن + كل المكتبات + البرنامج، في ملف zip واحد يُنقل للسيرفر المعزول.
#>
param(
  [string]$PythonVersion = "3.12.10",
  [string]$Out = "dist\field-cases-server-windows"
)
$ErrorActionPreference = "Stop"
$root = Resolve-Path "$PSScriptRoot\..\.."
Set-Location $root
if (Test-Path $Out) { Remove-Item $Out -Recurse -Force }
New-Item -ItemType Directory -Force -Path $Out | Out-Null

$embed = "python-$PythonVersion-embed-amd64.zip"
Invoke-WebRequest "https://www.python.org/ftp/python/$PythonVersion/$embed" -OutFile "dist\$embed"
Expand-Archive "dist\$embed" -DestinationPath "$Out\python"

# مسارات Python المضمّن: مكتباته + مجلد البرنامج.
$pth = Get-ChildItem "$Out\python\python*._pth" | Select-Object -First 1
$zipName = (Get-ChildItem "$Out\python\python*.zip" | Select-Object -First 1).Name
Set-Content $pth.FullName -Encoding ASCII -Value @($zipName, ".", "Lib\site-packages", "..", "import site")

python -m pip install --no-compile --only-binary=:all: --platform win_amd64 `
  --python-version $PythonVersion.Substring(0, 4) --target "$Out\python\Lib\site-packages" -r requirements.txt
if ($LASTEXITCODE -ne 0) { throw "pip install failed" }

Copy-Item -Recurse app, migrations "$Out\"
Copy-Item manage.py, run_server.py, run_local.py, alembic.ini, config.example.ini, requirements.txt "$Out\"
Copy-Item deploy\windows\*.cmd, deploy\windows\install.ps1, deploy\windows\uninstall.ps1 "$Out\"
Copy-Item docs\INSTALL_WINDOWS.md, docs\LOCAL_QUICKSTART.md "$Out\"
Get-ChildItem $Out -Recurse -Directory -Filter __pycache__ | Remove-Item -Recurse -Force

Compress-Archive -Path "$Out\*" -DestinationPath "$Out.zip" -Force
Write-Host "Bundle: $Out.zip"
