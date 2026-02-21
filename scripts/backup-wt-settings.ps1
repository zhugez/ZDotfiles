$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$wtDir = Join-Path $env:LOCALAPPDATA "Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState"
$wtSettings = Join-Path $wtDir "settings.json"

if (!(Test-Path $wtSettings)) {
  Write-Host "Windows Terminal settings not found at: $wtSettings"
  exit 1
}

$backupDir = Join-Path $repoRoot "windows-terminal/backups"
if (!(Test-Path $backupDir)) {
  New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$backupFile = Join-Path $backupDir "settings.$ts.json"
Copy-Item $wtSettings $backupFile -Force
Write-Host "Backup created: $backupFile"
