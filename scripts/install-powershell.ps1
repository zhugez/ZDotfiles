[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ProfilePath = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1'),
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$ProfilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ProfilePath)
$profileDirectory = Split-Path -Parent $ProfilePath
$repoRoot = Split-Path -Parent $PSScriptRoot
$files = [ordered]@{
    $ProfilePath = Join-Path $repoRoot 'powershell\Microsoft.PowerShell_profile.ps1'
    (Join-Path $profileDirectory 'zdotfiles.zhugez.omp.json') = Join-Path $repoRoot 'windows-terminal\zhugez.omp.json'
}

$changes = @(
    foreach ($destination in $files.Keys) {
        $source = $files[$destination]
        $content = [IO.File]::ReadAllText($source)
        if (-not (Test-Path -LiteralPath $destination) -or
            [IO.File]::ReadAllText($destination) -cne $content) {
            $destination
        }
    }
)

if (-not $changes.Count) {
    Write-Output 'PowerShell profile and theme are up to date.'
    return
}

foreach ($destination in $changes) {
    if ((Test-Path -LiteralPath $destination) -and -not $Force) {
        throw "File already exists at '$destination'. Review it or use -Force to replace it with a backup."
    }
}

if ($PSCmdlet.ShouldProcess($profileDirectory, 'Install the ZDotfiles PowerShell profile and theme')) {
    $null = [IO.Directory]::CreateDirectory($profileDirectory)
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
    foreach ($destination in $changes) {
        if (Test-Path -LiteralPath $destination) {
            $backup = "$destination.bak-$stamp"
            Copy-Item -LiteralPath $destination -Destination $backup
            Write-Output "Backed up: $backup"
        }
    }
    foreach ($destination in $changes) {
        [IO.File]::Copy($files[$destination], $destination, $true)
        Write-Output "Installed: $destination"
    }
}
