# dotfiles

Personal development environment configuration with cross-platform support.

## Included

- `zsh/.config/zsh/` — shell profile and aliases
- `git/.config/git/` — git defaults + work/personal profile split
- `tmux/.config/tmux/` — tmux setup
- `nvim/.config/nvim/` — minimal Neovim defaults
- `starship/.config/starship.toml` — prompt theme
- `wezterm/.config/wezterm/` — WezTerm config
- `windows-terminal/` — Windows Terminal settings/profile
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
- Font recommended: **JetBrainsMono Nerd Font**

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
