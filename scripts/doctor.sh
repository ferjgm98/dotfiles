#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
ISSUES=0

check_link() {
  local src="$1" dest="$2"
  if [[ -L "$dest" && "$dest" -ef "$src" ]]; then
    printf '[OK] %s\n' "$dest"
  elif [[ -f "$dest" && -f "$src" ]] && cmp -s "$src" "$dest"; then
    printf '[COPY] Matches repo but is not linked: %s\n' "$dest"
  else
    printf '[CHECK] Missing, different, or linked elsewhere: %s\n' "$dest"
    ISSUES=1
  fi
}

check_link "$DOTFILES_DIR/zsh/.zshrc" "${ZDOTDIR:-$HOME}/.zshrc"
check_link "$DOTFILES_DIR/zsh/.zsh_plugins.txt" "${ZDOTDIR:-$HOME}/.zsh_plugins.txt"
check_link "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
check_link "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
check_link "$DOTFILES_DIR/starship/starship.toml" "$CONFIG_DIR/starship.toml"
check_link "$DOTFILES_DIR/nvim/nvim" "$CONFIG_DIR/nvim"

if [[ -L "$DOTFILES_DIR/nvim/nvim/nvim" && "$DOTFILES_DIR/nvim/nvim/nvim" -ef "$DOTFILES_DIR/nvim/nvim" ]]; then
  printf '[CHECK] Recursive Neovim link: %s/nvim/nvim/nvim\n' "$DOTFILES_DIR"
  ISSUES=1
fi
for tool in zsh git rsync tmux nvim starship fzf fd bat eza zoxide; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf '[MISSING] %s\n' "$tool"
    ISSUES=1
  fi
done
exit "$ISSUES"
