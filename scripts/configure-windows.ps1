#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$TerminalSettingsPath,
    [Parameter(Mandatory)][string]$Font
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$manifest = Import-PowerShellDataFile (Join-Path $PSScriptRoot 'windows-packages.psd1')
foreach ($module in $manifest.Modules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Installing PowerShell module: $module"
        Install-Module -Name $module -Repository PSGallery -Scope CurrentUser -Force
    }
}

& (Join-Path $PSScriptRoot 'install-powershell.ps1') -Force

$terminalSource = Get-Content -LiteralPath (Join-Path $repoRoot 'windows-terminal/settings.json') -Raw | ConvertFrom-Json -AsHashtable
$terminalProfileId = $terminalSource.defaultProfile
$existing = Test-Path -LiteralPath $TerminalSettingsPath
$terminal = if ($existing) {
    Get-Content -LiteralPath $TerminalSettingsPath -Raw | ConvertFrom-Json -AsHashtable
} else {
    $terminalSource
}
$before = $terminal | ConvertTo-Json -Depth 100 -Compress

if (-not $terminal.profiles) { $terminal.profiles = @{} }
$terminal.profiles.list = @($terminal.profiles.list | Where-Object { $_ })
$pwshProfile = $terminal.profiles.list | Where-Object { $_.guid -eq $terminalProfileId } | Select-Object -First 1
if (-not $pwshProfile) {
    $pwshProfile = @{ guid = $terminalProfileId; name = 'PowerShell'; source = 'Windows.Terminal.PowershellCore' }
    $terminal.profiles.list += $pwshProfile
}
$pwshProfile.hidden = $false
if (-not $pwshProfile.font) { $pwshProfile.font = @{} }
$pwshProfile.font.face = $Font
$terminal.defaultProfile = $terminalProfileId

foreach ($scheme in $terminalSource.schemes) {
    if ($scheme.name -notin @($terminal.schemes.name)) {
        $terminal.schemes = @($terminal.schemes | Where-Object { $_ }) + @($scheme)
    }
}
if (-not $existing -or ($terminal | ConvertTo-Json -Depth 100 -Compress) -cne $before) {
    $null = New-Item -Path (Split-Path -Parent $TerminalSettingsPath) -ItemType Directory -Force
    if ($existing) {
        $backup = "$TerminalSettingsPath.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss-fff')"
        Copy-Item -LiteralPath $TerminalSettingsPath -Destination $backup
        Write-Host "Backed up: $backup"
    }
    $terminal | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $TerminalSettingsPath -Encoding utf8
}

$nvimDirectory = Join-Path $env:LOCALAPPDATA 'nvim'
$nvimInit = Join-Path $nvimDirectory 'init.lua'
if (-not (Test-Path -LiteralPath $nvimInit) -and -not (Test-Path -LiteralPath (Join-Path $nvimDirectory 'init.vim'))) {
    $null = New-Item -Path $nvimDirectory -ItemType Directory -Force
    Copy-Item -LiteralPath (Join-Path $repoRoot 'nvim/.config/nvim/init.lua') -Destination $nvimInit
}
