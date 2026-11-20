[CmdletBinding(DefaultParameterSetName = 'Update')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Enable')][switch]$EnableAutomatic,
    [Parameter(Mandatory, ParameterSetName = 'Disable')][switch]$DisableAutomatic
)

$ErrorActionPreference = 'Stop'
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$taskName = "ZDotfiles-PowerShell-Update-$($identity.User.Value)"

if ($DisableAutomatic) {
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }
    Write-Host 'ZDotfiles automatic PowerShell task is disabled. Windows Update settings are unchanged.'
    return
}

$pwsh = Get-Command pwsh.exe -CommandType Application -ErrorAction Stop | Select-Object -First 1
$installDirectory = & $pwsh.Source -NoProfile -NonInteractive -Command '$PSHOME'
if ($LASTEXITCODE -or -not $installDirectory) { throw 'Could not identify the active PowerShell 7 installation.' }

$scoop = Get-Command scoop -CommandType ExternalScript,Application -ErrorAction SilentlyContinue | Select-Object -First 1
$winget = Get-Command winget.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
$coreRegistry = 'HKLM:\SOFTWARE\Microsoft\PowerShellCore'
$msi = Get-ChildItem -LiteralPath "$coreRegistry\InstalledVersions" -ErrorAction SilentlyContinue | ForEach-Object {
    Get-ItemProperty -LiteralPath $_.PSPath
} | Where-Object { $_.ProductCode -and ([string]$_.InstallLocation).TrimEnd('\') -eq $installDirectory.TrimEnd('\') }

if ($msi) {
    $useMicrosoftUpdate = (Get-ItemProperty -LiteralPath $coreRegistry -Name UseMU -ErrorAction SilentlyContinue).UseMU
    $manager = New-Object -ComObject Microsoft.Update.ServiceManager
    $registered = $manager.Services | Where-Object { $_.ServiceID -eq '7971f918-a847-4430-9279-4a52d1efe18d' -and $_.IsRegisteredWithAU }
    if ($useMicrosoftUpdate -eq 1 -and $registered) {
        Write-Host 'This PowerShell MSI receives updates through Microsoft Update in its current release channel.'
    } else {
        Write-Warning 'Microsoft Update is not enabled for this PowerShell MSI. Enable the two Microsoft Update options in the official MSI or follow the PowerShell Microsoft Update FAQ.'
    }
    if (-not $EnableAutomatic) { Write-Host 'To check now, open Settings > Windows Update > Check for updates.' }
    return
}

if ($scoop -and ((Split-Path -Parent $pwsh.Source) -eq (Split-Path -Parent $scoop.Source) -or
    $installDirectory -like '*\apps\pwsh\*')) {
    $provider = 'Scoop'
    $command = @'
& '__MANAGER__' update
if ($LASTEXITCODE) { exit $LASTEXITCODE }
& '__MANAGER__' update pwsh
exit $LASTEXITCODE
'@
    $command = $command.Replace('__MANAGER__', $scoop.Source.Replace("'", "''"))
} elseif ($winget -and $installDirectory -like '*\WindowsApps\Microsoft.PowerShell_*') {
    $provider = 'WinGet'
    $command = @'
& '__MANAGER__' upgrade --id Microsoft.PowerShell --exact --source winget --silent --disable-interactivity --accept-package-agreements --accept-source-agreements
$upgradeResult = $LASTEXITCODE
if ($upgradeResult -eq -1978335189) { exit 0 } # No applicable update
exit $upgradeResult
'@
    $command = $command.Replace('__MANAGER__', $winget.Source.Replace("'", "''"))
} else {
    if ($installDirectory -like '*\WindowsApps\Microsoft.PowerShell_*') {
        Write-Host 'Use Microsoft Store app updates for this PowerShell package.'
    } else {
        Write-Warning 'No supported updater was found for this PowerShell installation.'
    }
    return
}

$encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes("`$ErrorActionPreference = 'Stop'`n$command"))
$windowsPowerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$arguments = "-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand $encoded"
if (-not $EnableAutomatic) {
    & $windowsPowerShell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand $encoded
    if ($LASTEXITCODE) { throw "$provider returned exit code $LASTEXITCODE." }
    return
}

$existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existing -and $existing.Actions.Arguments -eq $arguments -and $existing.State -ne 'Disabled') {
    Write-Host "Automatic PowerShell updates via $provider are already configured."
    return
}
$action = New-ScheduledTaskAction -Execute $windowsPowerShell -Argument $arguments
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At ([datetime]::Today.AddHours(10))
$principal = New-ScheduledTaskPrincipal -UserId $identity.User.Value -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew
$null = Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal `
    -Settings $settings -Description 'Update the current user PowerShell 7 package weekly via ZDotfiles.' -Force
Write-Host "Automatic PowerShell updates via $provider are scheduled weekly while you are signed in."

