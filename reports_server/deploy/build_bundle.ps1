# Build the offline Windows folder: embedded Python + libraries + launcher + bundle.enc
param(
  [string]$PythonVersion = "3.12.10",
  [string]$BundleEnc = "",
  [string]$Out = "dist\reports-server-windows"
)
$ErrorActionPreference = "Stop"
$root = Resolve-Path "$PSScriptRoot\.."
Set-Location $root
if (Test-Path $Out) { Remove-Item $Out -Recurse -Force }
New-Item -ItemType Directory -Force -Path $Out | Out-Null

$embed = "python-$PythonVersion-embed-amd64.zip"
Invoke-WebRequest "https://www.python.org/ftp/python/$PythonVersion/$embed" -OutFile "dist\$embed"
Expand-Archive "dist\$embed" -DestinationPath "$Out\python"
$pth = Get-ChildItem "$Out\python\python*._pth" | Select-Object -First 1
$zipName = (Get-ChildItem "$Out\python\python*.zip" | Select-Object -First 1).Name
Set-Content $pth.FullName -Encoding ASCII -Value @($zipName, ".", "Lib\site-packages", "..", "import site")

python -m pip install --no-compile --only-binary=:all: --platform win_amd64 `
  --python-version $PythonVersion.Substring(0, 4) --target "$Out\python\Lib\site-packages" -r requirements.txt
if ($LASTEXITCODE -ne 0) { throw "pip install failed" }

Copy-Item run_reports.py, requirements.txt "$Out\"
Copy-Item deploy\*.cmd "$Out\"
Copy-Item "docs\اقرأني.txt" "$Out\"
if ($BundleEnc) { Copy-Item $BundleEnc "$Out\bundle.enc" }
Get-ChildItem $Out -Recurse -Directory -Filter __pycache__ | Remove-Item -Recurse -Force
Write-Host "Folder: $Out"
