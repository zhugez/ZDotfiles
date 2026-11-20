# Keep automation and redirected output free of interactive setup.
if ([Environment]::GetCommandLineArgs() -contains '-NonInteractive' -or
    [Console]::IsInputRedirected -or [Console]::IsOutputRedirected) {
    return
}

Import-Module PSReadLine
if (Get-Module -ListAvailable Terminal-Icons) {
    Import-Module Terminal-Icons
}
Set-PSReadLineOption -EditMode Windows -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle InlineView -MaximumHistoryCount 10000
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# Load the fuzzy finder on the first search.
if ((Get-Command fzf.exe -ErrorAction Ignore) -and (Get-Module -ListAvailable PSFzf)) {
    Set-PSReadLineKeyHandler -Key Ctrl+r -BriefDescription FuzzyHistory -ScriptBlock {
        PSFzf\Invoke-FzfPsReadlineHandlerHistory
    }
    Set-PSReadLineKeyHandler -Key Ctrl+t -BriefDescription FuzzyFiles -ScriptBlock {
        PSFzf\Invoke-FzfPsReadlineHandlerProvider
    }
}

# posh-git installs its own completer on first use.
if ((Get-Command git.exe -ErrorAction Ignore) -and (Get-Module -ListAvailable posh-git)) {
    Register-ArgumentCompleter -Native -CommandName git,git.exe -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)

        $length = $cursorPosition - $commandAst.Extent.StartOffset
        $command = $commandAst.Extent.Text.PadRight($length).Substring(0, $length)
        posh-git\Expand-GitCommand ($command -replace '^git\.exe(?=\s|$)', 'git')
    }
}

function y {
    $yazi = Get-Command yazi.exe -CommandType Application -ErrorAction SilentlyContinue
    if (-not $yazi) {
        Write-Error 'Yazi is missing. Run scripts/bootstrap.ps1 from ZDotfiles.'
        return
    }
    $cwdFile = [IO.Path]::GetTempFileName()
    try {
        & $yazi.Source @args "--cwd-file=$cwdFile"
        if ($LASTEXITCODE -eq 0) {
            $cwd = [IO.File]::ReadAllText($cwdFile).TrimEnd([char]13, [char]10)
            if ($cwd -and (Test-Path -LiteralPath $cwd -PathType Container)) {
                Set-Location -LiteralPath $cwd
            }
        }
    } finally {
        [IO.File]::Delete($cwdFile)
    }
}

function ll { Get-ChildItem -Force @args }
function up { Set-Location .. }
function gst { git status --short --branch @args }
function gdiff { git diff @args }
function glog { git log --oneline --graph -15 @args }

if (-not $env:EDITOR -and (Get-Command nvim.exe -ErrorAction Ignore)) {
    $env:EDITOR = 'nvim'
}

$poshTheme = Join-Path $HOME '.poshthemes\M365Princess.omp.json'
if (-not (Test-Path -LiteralPath $poshTheme)) {
    $poshTheme = Join-Path $PSScriptRoot 'zdotfiles.zhugez.omp.json'
}
if ((Get-Command oh-my-posh.exe -ErrorAction Ignore) -and (Test-Path -LiteralPath $poshTheme)) {
    oh-my-posh.exe init pwsh --config $poshTheme | Invoke-Expression
}

$zoxideCommand = Get-Command zoxide.exe -CommandType Application -ErrorAction Ignore | Select-Object -First 1
if ($zoxideCommand) {
    $zoxideInit = & $zoxideCommand.Source init powershell | Out-String
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($zoxideInit)) {
        Invoke-Expression $zoxideInit
    } else {
        Write-Warning 'zoxide did not initialize. Run zoxide.exe --version to check the installation.'
    }
}
