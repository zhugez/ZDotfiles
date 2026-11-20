[CmdletBinding()]
param(
    [switch]$Plan,
    [switch]$SkipMsvc
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$PSNativeCommandUseErrorActionPreference = $false
if ($env:OS -ne 'Windows_NT') { throw 'This bootstrap is for Windows.' }
# Windows PowerShell may default to older TLS versions.
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$manifest = Import-PowerShellDataFile (Join-Path $PSScriptRoot 'windows-packages.psd1')

function Update-ProcessPath {
    $parts = @($env:Path -split ';')
    foreach ($scope in 'Machine', 'User') {
        $storedPath = [Environment]::GetEnvironmentVariable('Path', $scope)
        $parts += [Environment]::ExpandEnvironmentVariables([string]$storedPath) -split ';'
    }
    $env:Path = ($parts | Where-Object { $_ } | Select-Object -Unique) -join ';'
}

function Invoke-Checked {
    param([string]$Program, [string[]]$Arguments, [int[]]$SuccessCodes = @(0))
    $global:LASTEXITCODE = 0
    & $Program @Arguments
    if ($LASTEXITCODE -notin $SuccessCodes) {
        throw "$Program failed ($LASTEXITCODE): $($Arguments -join ' ')"
    }
}

function Find-Tool {
    param([string]$Name)
    if ($Name -eq 'wt.exe' -and (Get-AppxPackage -Name Microsoft.WindowsTerminal)) { return $true }
    $commands = Get-Command $Name -All -CommandType Application,ExternalScript -ErrorAction SilentlyContinue
    if ($Name -in @('wt.exe', 'python.exe')) {
        $commands = $commands | Where-Object Source -notlike '*\Microsoft\WindowsApps\*'
    }
    $commands | Select-Object -First 1
}

function Add-ScoopBucket {
    param([string]$Name)
    if ($Name -notin @(scoop bucket list | ForEach-Object { $_.Name })) {
        Invoke-Checked 'scoop' @('bucket', 'add', $Name)
    }
}

function Add-SevenZipToPath {
    $sevenZipDirectory = Join-Path $env:ProgramFiles '7-Zip'
    if (-not (Find-Tool '7z.exe') -and (Test-Path -LiteralPath (Join-Path $sevenZipDirectory '7z.exe'))) {
        $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        if ($sevenZipDirectory -notin ($userPath -split ';')) {
            [Environment]::SetEnvironmentVariable('Path', ((@($userPath, $sevenZipDirectory) | Where-Object { $_ }) -join ';'), 'User')
            Update-ProcessPath
        }
    }
}

function Install-DevPackage {
    param([hashtable]$Package)
    if (Find-Tool $Package.Command) {
        Write-Host "Already available: $($Package.Command)"
        return
    }
    Write-Host "Installing: $($Package.Command)"
    if ($useWinget) {
        Invoke-Checked 'winget.exe' @('install', '--id', $Package.Winget, '--exact', '--source', 'winget',
            '--silent', '--disable-interactivity', '--accept-package-agreements', '--accept-source-agreements')
    } elseif ($Package.Scoop -eq 'bun' -and (Test-Path -LiteralPath (Join-Path $HOME '.bun') -PathType Container)) {
        # Keep existing Bun data in place when restoring a missing executable.
        Invoke-DownloadedInstaller 'https://bun.com/install.ps1' 'ps1' {
            param($path)
            Invoke-Checked 'powershell.exe' @('-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', $path)
        }
    } else {
        if ($Package.Scoop -match '^([^/]+)/') { Add-ScoopBucket $Matches[1] }
        Invoke-Checked 'scoop' @('install', $Package.Scoop)
    }
    Update-ProcessPath
}

function Invoke-DownloadedInstaller {
    param([string]$Uri, [string]$Extension, [scriptblock]$Run)
    $path = Join-Path ([IO.Path]::GetTempPath()) ("zdotfiles-" + [guid]::NewGuid() + ".$Extension")
    try {
        Invoke-WebRequest -UseBasicParsing -Uri $Uri -OutFile $path
        & $Run $path
    } finally {
        [IO.File]::Delete($path)
    }
}

function Install-MsvcTools {
    $vswhere = Join-Path $env:ProgramFiles 'Microsoft Visual Studio\Installer\vswhere.exe'
    if ($env:ProgramFiles -and [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')) {
        $vswhere = Join-Path ([Environment]::GetEnvironmentVariable('ProgramFiles(x86)')) 'Microsoft Visual Studio\Installer\vswhere.exe'
    }
    if ((Test-Path -LiteralPath $vswhere) -and
        (& $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath)) {
        return
    }
    Write-Host 'Installing Visual Studio C++ Build Tools for Rust. Windows may ask for elevation.'
    Invoke-DownloadedInstaller 'https://aka.ms/vs/17/release/vs_BuildTools.exe' 'exe' {
        param($path)
        $process = Start-Process -FilePath $path -ArgumentList '--quiet', '--wait', '--norestart',
            '--add', 'Microsoft.VisualStudio.Workload.VCTools', '--includeRecommended' -Verb RunAs -WindowStyle Hidden -PassThru -Wait
        if ($process.ExitCode -eq 3010) { Write-Warning 'C++ Build Tools require a Windows restart.' }
        elseif ($process.ExitCode -ne 0) { throw "C++ Build Tools failed ($($process.ExitCode))." }
    }
}

Update-ProcessPath
$useWinget = $false
if (Get-Command winget.exe -ErrorAction SilentlyContinue) {
    & winget.exe --version *> $null
    $useWinget = $LASTEXITCODE -eq 0
}
$manager = if ($useWinget) { 'WinGet' } else { 'Scoop' }
Write-Host "Package manager: $manager"

if ($Plan) {
    $manifest.Packages | ForEach-Object {
        if ($useWinget) { "WinGet: $($_.Winget)" } else { "Scoop: $($_.Scoop)" }
    }
    if (-not $useWinget -and -not (Find-Tool 'scoop')) { 'Install Scoop if missing' }
    'Install Herdr (official stable Windows installer) and a Nerd Font if missing'
    if (-not $SkipMsvc) { 'Install MSVC Build Tools if needed for Rust' }
    "Install PowerShell modules: $($manifest.Modules -join ', ')"
    'Configure PowerShell 7, Windows Terminal, Neovim and Yazi'
    return
}

if (-not $useWinget -and -not (Find-Tool 'scoop')) {
    Write-Host 'Installing Scoop for the current Windows user.'
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $admin = [Security.Principal.WindowsPrincipal]::new($identity).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    Invoke-DownloadedInstaller 'https://get.scoop.sh' 'ps1' {
        param($path)
        $arguments = @('-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', $path)
        if ($admin) { $arguments += '-RunAsAdmin' }
        Invoke-Checked 'powershell.exe' $arguments
    }
    Update-ProcessPath
    if (-not (Find-Tool 'scoop')) { throw 'Scoop is not on PATH after installation.' }
}

Add-SevenZipToPath

foreach ($package in $manifest.Packages) {
    if ($package.Command -eq 'rustup.exe' -and -not $SkipMsvc) {
        $activeRust = if (Find-Tool 'rustup.exe') { & rustup.exe show active-toolchain 2>$null }
        if ($activeRust -notmatch '-gnu(?:\s|$)') { Install-MsvcTools }
    }
    Install-DevPackage $package
    if ($package.Command -eq '7z.exe') { Add-SevenZipToPath }
}
if (-not (Find-Tool 'rustup.exe')) { throw 'Rustup is not on PATH after installation.' }
& rustup.exe show active-toolchain *> $null
if ($LASTEXITCODE -ne 0) { Invoke-Checked 'rustup.exe' @('default', 'stable') }

if (-not (Find-Tool 'herdr.exe')) {
    Write-Host 'Installing stable Herdr.'
    Invoke-DownloadedInstaller 'https://herdr.dev/install.ps1' 'ps1' {
        param($path)
        Invoke-Checked 'powershell.exe' @('-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
            '-File', $path, '-Channel', 'stable')
    }
    Update-ProcessPath
}

$fontKeys = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts', 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
$fontNames = @(
    foreach ($key in $fontKeys) {
        if (Test-Path -LiteralPath $key) { (Get-Item -LiteralPath $key).Property }
    }
)
$font = if ($fontNames -match '^GoogleSansCode NFM(?: \(TrueType\)|$)') { 'GoogleSansCode NFM' }
else { 'JetBrainsMono Nerd Font' }
if ($font -eq 'JetBrainsMono Nerd Font' -and -not ($fontNames -match '^JetBrainsMono\s*(Nerd\s*Font|NF)[ (.-]')) {
    if ($useWinget) {
        Invoke-Checked 'winget.exe' @('install', '--id', 'DEVCOM.JetBrainsMonoNerdFont', '--exact', '--source', 'winget',
            '--silent', '--disable-interactivity', '--accept-package-agreements', '--accept-source-agreements')
    } else {
        Add-ScoopBucket 'nerd-fonts'
        Invoke-Checked 'scoop' @('install', 'nerd-fonts/JetBrainsMono-NF')
    }
}

# Yazi needs the Unicode-capable file.exe supplied by Git for Windows.
$gitExecPath = & git.exe --exec-path
if ($LASTEXITCODE -ne 0) { throw 'Could not find the Git for Windows installation.' }
$fileOne = [IO.Path]::GetFullPath((Join-Path $gitExecPath '../../../usr/bin/file.exe'))
if (-not (Test-Path -LiteralPath $fileOne)) { throw "Could not find Git for Windows file.exe at $fileOne" }
if (-not (Test-Path -LiteralPath ([string]$env:YAZI_FILE_ONE))) {
    [Environment]::SetEnvironmentVariable('YAZI_FILE_ONE', $fileOne, 'User')
    $env:YAZI_FILE_ONE = $fileOne
}

$terminalPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
if (-not (Get-AppxPackage -Name Microsoft.WindowsTerminal) -and (Find-Tool 'scoop')) {
    $prefix = & scoop prefix windows-terminal 2>$null | Select-Object -Last 1
    if ($LASTEXITCODE -eq 0 -and $prefix -and (Test-Path -LiteralPath $prefix)) {
        $terminalPath = Join-Path $prefix 'settings\settings.json'
    }
}

foreach ($tool in 'pwsh.exe', 'yazi.exe', 'herdr.exe') {
    if (-not (Find-Tool $tool)) { throw "$tool is not on PATH. Open a fresh terminal and rerun the bootstrap." }
}
Invoke-Checked 'pwsh.exe' @('-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
    '-File', (Join-Path $PSScriptRoot 'configure-windows.ps1'), '-TerminalSettingsPath', $terminalPath, '-Font', $font)
Write-Host 'Setup complete. Open a new PowerShell tab. Run y for Yazi or herdr for a terminal session.'

