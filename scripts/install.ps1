Param(
  [switch]$BackupOnly,
  [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$wtSettingsSrc = Join-Path $repoRoot "windows-terminal/settings.json"
$wtDir = Join-Path $env:LOCALAPPDATA "Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState"
$wtSettingsDst = Join-Path $wtDir "settings.json"

if (!(Test-Path $wtSettingsSrc)) {
  throw "Source settings.json not found: $wtSettingsSrc"
}

if (!(Test-Path $wtDir)) {
  New-Item -ItemType Directory -Path $wtDir -Force | Out-Null
}

$backupDir = Join-Path $repoRoot "windows-terminal/backups"
if (!(Test-Path $backupDir)) {
  New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}

if (Test-Path $wtSettingsDst) {
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  $backupFile = Join-Path $backupDir "settings.$ts.json"
  Copy-Item $wtSettingsDst $backupFile -Force
  Write-Host "Backed up existing settings to: $backupFile"
} else {
  Write-Host "No existing Windows Terminal settings found."
}

if ($BackupOnly) {
  Write-Host "Backup complete (BackupOnly mode)."
  exit 0
}

if ((Test-Path $wtSettingsDst) -and -not $Force) {
  Write-Host "Destination exists: $wtSettingsDst"
  Write-Host "Use -Force to overwrite after backup."
  exit 1
}

Copy-Item $wtSettingsSrc $wtSettingsDst -Force
Write-Host "Applied Windows Terminal settings to: $wtSettingsDst"
