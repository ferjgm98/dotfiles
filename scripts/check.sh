#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for script in "$DOTFILES_DIR"/scripts/*.sh; do
  bash -n "$script"
done
zsh -n "$DOTFILES_DIR/zsh/.zshrc"
python3 -m unittest discover -s "$DOTFILES_DIR/tests" -v
