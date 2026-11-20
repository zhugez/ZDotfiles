#!/usr/bin/env bash
set -euo pipefail

if ! command -v stow >/dev/null 2>&1; then
  echo "Please install stow first" >&2
  exit 1
fi

cd -- "$(dirname -- "$0")/.."
stow --target="$HOME" zsh git nvim starship wezterm

if ! command -v herdr >/dev/null 2>&1; then
  curl -fsSL https://herdr.dev/install.sh | sh
fi

echo "Dotfiles linked. Start a terminal session with herdr."
