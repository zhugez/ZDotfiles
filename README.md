# dotfiles

Personal development environment configuration (shell, git, tmux, editor).

## Structure

- `zsh/.config/zsh/` — shell config
- `git/.config/git/` — git config templates
- `tmux/.config/tmux/` — tmux config
- `nvim/.config/nvim/` — neovim config
- `scripts/` — setup/install helpers

## Quick start (GNU stow)

```bash
sudo apt install stow   # or brew install stow
cd ~/dotfiles
stow zsh git tmux nvim
```

## Notes

- Keep machine-specific secrets out of this repository.
- Use local overrides for private tokens/keys.
