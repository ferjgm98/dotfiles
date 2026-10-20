#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=0
WITH_TMUX=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-tmux) WITH_TMUX=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) echo "Usage: link.sh [--dry-run] [--with-tmux]"; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 1 ;;
  esac
  shift
done

source "$DOTFILES_DIR/scripts/link-common.sh"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

backup_and_link "$DOTFILES_DIR/zsh/.zshrc" "${ZDOTDIR:-$HOME}/.zshrc"
backup_and_link "$DOTFILES_DIR/zsh/.zsh_plugins.txt" "${ZDOTDIR:-$HOME}/.zsh_plugins.txt"
if [[ "$WITH_TMUX" -eq 1 ]]; then
  backup_and_link "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
  backup_and_link "$DOTFILES_DIR/tmux/scripts/git-status.sh" "$HOME/.tmux/scripts/git-status.sh"
fi
backup_and_link "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
backup_and_link "$DOTFILES_DIR/starship/starship.toml" "$CONFIG_DIR/starship.toml"
backup_and_link "$DOTFILES_DIR/nvim/nvim" "$CONFIG_DIR/nvim"

backup_and_link "$DOTFILES_DIR/ghostty/config" "$CONFIG_DIR/ghostty/config"
backup_and_link "$DOTFILES_DIR/herdr/config.toml" "${HERDR_CONFIG_PATH:-$CONFIG_DIR/herdr/config.toml}"
if [[ "$(uname -s)" == Darwin ]]; then
  backup_and_link "$DOTFILES_DIR/ghostty/config" "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
  backup_and_link "$DOTFILES_DIR/cmux/cmux.json" "$CONFIG_DIR/cmux/cmux.json"
fi
