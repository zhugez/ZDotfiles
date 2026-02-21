#!/usr/bin/env bash
set -euo pipefail

if ! command -v stow >/dev/null 2>&1; then
  echo "Please install stow first" >&2
  exit 1
fi

stow zsh git tmux nvim starship wezterm

echo "Dotfiles linked successfully."
