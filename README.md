# dotfiles

Personal development environment configuration with cross-platform support.

## Included

- `zsh/.config/zsh/` — shell profile and aliases
- `git/.config/git/` — git defaults + work/personal profile split
- `tmux/.config/tmux/` — tmux setup
- `nvim/.config/nvim/` — minimal Neovim defaults
- `starship/.config/starship.toml` — prompt theme
- `wezterm/.config/wezterm/` — WezTerm config
- `powershell/` — PowerShell 7 profile
- `windows-terminal/` — Windows Terminal settings and Oh My Posh theme
- `scripts/bootstrap.sh` — bootstrap via GNU stow

## Quick Start

```bash
sudo apt install stow   # or brew install stow
cd ~/dotfiles
./scripts/bootstrap.sh
```

## Windows Terminal

- Import/merge `windows-terminal/settings.json` into:
  - `%LOCALAPPDATA%/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json`
- The PowerShell 7 profile uses **GoogleSansCode NFM** for file and prompt icons. Install that font or choose another installed Nerd Font for the profile. Other profiles use the repo's **JetBrainsMono Nerd Font** default.

## Security Notes

- Keep secrets/tokens out of this repo
- Use local overrides for machine-specific credentials

## Windows one-command setup (PowerShell)

```powershell
# backup current Windows Terminal settings
./scripts/backup-wt-settings.ps1

# apply repo settings (with backup + overwrite)
./scripts/install.ps1 -Force
```

Options:
- `-BackupOnly` : backup only, do not apply
- `-Force` : overwrite destination settings.json after backup

## PowerShell 7

From the repository root, in PowerShell 7:

```powershell
./scripts/install-powershell.ps1 -WhatIf
./scripts/install-powershell.ps1
```

If a different profile already exists, review it first. Use `-Force` to replace it and keep a timestamped backup beside the original, or copy the settings you want into your existing profile. Open a new PowerShell tab after installation.

- `Tab` opens command and path completion. `↑` and `↓` search history by prefix, and PSReadLine shows inline predictions.
- `Ctrl+R` searches history and `Ctrl+T` inserts a file path when both PSFzf and fzf are available.
- `z` and `zi` jump to previously visited folders when zoxide is available.
- `ls`, `dir`, and `ll` show icons when Terminal-Icons is available. `ll` also shows hidden entries.
- `gst`, `gdiff`, and `glog` are Git shortcuts. Git completion uses posh-git on first use.
- Oh My Posh uses the local M365Princess theme if present and falls back to the included Zhugez theme. Neovim becomes the default editor if installed and `EDITOR` is unset.

Install only the optional tools you use. PowerShell 7 includes PSReadLine. The optional PowerShell modules are Terminal-Icons, PSFzf, and posh-git. The profile skips interactive setup for redirected sessions and scripts run with `-NonInteractive`.
