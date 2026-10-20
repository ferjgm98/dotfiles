#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
ISSUES=0
WITH_TMUX=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-tmux) WITH_TMUX=1 ;;
    -h|--help) echo "Usage: doctor.sh [--with-tmux]"; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 1 ;;
  esac
  shift
done

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
if [[ "$WITH_TMUX" -eq 1 ]]; then
  check_link "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
  check_link "$DOTFILES_DIR/tmux/scripts/git-status.sh" "$HOME/.tmux/scripts/git-status.sh"
  command -v tmux >/dev/null 2>&1 || { echo '[MISSING] tmux'; ISSUES=1; }
fi
check_link "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
check_link "$DOTFILES_DIR/starship/starship.toml" "$CONFIG_DIR/starship.toml"
check_link "$DOTFILES_DIR/nvim/nvim" "$CONFIG_DIR/nvim"

if [[ -L "$DOTFILES_DIR/nvim/nvim/nvim" && "$DOTFILES_DIR/nvim/nvim/nvim" -ef "$DOTFILES_DIR/nvim/nvim" ]]; then
  printf '[CHECK] Recursive Neovim link: %s/nvim/nvim/nvim\n' "$DOTFILES_DIR"
  ISSUES=1
fi
check_link "$DOTFILES_DIR/ghostty/config" "$CONFIG_DIR/ghostty/config"
check_link "$DOTFILES_DIR/herdr/config.toml" "${HERDR_CONFIG_PATH:-$CONFIG_DIR/herdr/config.toml}"
if [[ "$(uname -s)" == Darwin ]]; then
  check_link "$DOTFILES_DIR/cmux/cmux.json" "$CONFIG_DIR/cmux/cmux.json"
  check_link "$DOTFILES_DIR/ghostty/config" "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
  [[ -d /Applications/cmux.app ]] || command -v cmux >/dev/null 2>&1 || { echo '[MISSING] cmux'; ISSUES=1; }
  [[ -d /Applications/Ghostty.app ]] || command -v ghostty >/dev/null 2>&1 || { echo '[MISSING] Ghostty'; ISSUES=1; }
else
  command -v ghostty >/dev/null 2>&1 || { echo '[MISSING] Ghostty'; ISSUES=1; }
fi
for tool in zsh git rsync herdr nvim starship fzf fd bat eza zoxide; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf '[MISSING] %s\n' "$tool"
    ISSUES=1
  fi
done
exit "$ISSUES"
