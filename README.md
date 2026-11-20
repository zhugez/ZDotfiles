# dotfiles

Personal development environment configuration for Windows and Unix.

## Windows quick start

Clone the repo, open a regular PowerShell window in the clone, and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\bootstrap.ps1
```

Use the same command with `-Plan` to see the package list without installing.
The bootstrap works from Windows PowerShell 5.1. It uses WinGet if available,
otherwise it uses Scoop and installs Scoop for the current user if needed.

- Developer runtimes: Node.js LTS, Bun, pnpm, Rust stable, Go, Python, and uv.
- Terminal and editor: PowerShell 7, Windows Terminal, Oh My Posh, a Nerd Font,
  Neovim, Git, GitHub CLI, zoxide, fzf, ripgrep, fd, bat, and jq.
- Yazi with file search, previews, and Git for Windows MIME detection.
- Native stable-channel Herdr, the default multiplexer for this setup.
- PowerShell modules: Terminal-Icons, PSFzf, and posh-git.

The bootstrap skips tools already on PATH. The MSVC build tools and Windows SDK
for Rust may take several minutes and Windows may prompt for elevation.
Use `-SkipMsvc` if you manage that toolchain yourself. Some installers may ask
for a restart. Rerun the same command if a package fails or after a required restart.

The bootstrap backs up an existing PowerShell profile before replacing it. It
merges the PowerShell entry and Zhugez color scheme into existing Windows
Terminal settings, backing up the file when it changes. It installs the
Neovim defaults when there is no existing Neovim init file.

Open a new PowerShell 7 tab. Run `y` to browse files, then press `q` to return
to PowerShell in the selected directory. Run `herdr` to open a multiplexer session.

## Linux and macOS

```bash
sudo apt install stow   # or brew install stow
cd ~/dotfiles
./scripts/bootstrap.sh
```

This links the Zsh, Git, Neovim, Starship, and WezTerm configs and installs
Herdr if missing. The legacy tmux config is still available for manual use.

## Advanced Windows setup

Use `./scripts/install-powershell.ps1` for profile-only installation.
Use `./scripts/backup-wt-settings.ps1` to back up the packaged Windows Terminal
configuration. The older Terminal-only installer, `./scripts/install.ps1 -Force`,
replaces Windows Terminal settings after making a backup.

## PowerShell 7

From the repository root, in PowerShell 7:

```powershell
./scripts/install-powershell.ps1 -WhatIf
./scripts/install-powershell.ps1
```

If a different profile already exists, review it first. Use `-Force` to replace it and keep a timestamped backup beside the original, or copy the settings you want into your existing profile. Open a new PowerShell tab after installation.

- `Tab` opens command and path completion. `↑` and `↓` search history by prefix, and PSReadLine shows inline predictions.
- `Ctrl+R` searches history and `Ctrl+T` inserts a file path when both PSFzf and fzf are available.
- `y` opens Yazi and carries the selected directory back to PowerShell.
- `z` and `zi` jump to previously visited folders when zoxide is available.
- `ls`, `dir`, and `ll` show icons when Terminal-Icons is available. `ll` also shows hidden entries.
- `gst`, `gdiff`, and `glog` are Git shortcuts. Git completion uses posh-git on first use.
- Oh My Posh uses the local M365Princess theme if present and falls back to the included Zhugez theme. Neovim becomes the default editor if installed and `EDITOR` is unset.

For a profile-only install, install only the optional tools you use. PowerShell 7 includes PSReadLine. The optional PowerShell modules are Terminal-Icons, PSFzf, and posh-git. The profile skips interactive setup for redirected sessions and scripts run with `-NonInteractive`.

Keep secrets and tokens out of the repo. Use local overrides for machine-specific credentials.
