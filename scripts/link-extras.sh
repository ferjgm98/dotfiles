#!/usr/bin/env bash
set -euo pipefail

# Optional linking for extras/ (captured allowlist).
# This keeps the main install minimal, but lets you restore more of ~/ when you want.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

info() { printf "[INFO] %s\n" "$1"; }
warn() { printf "[WARN] %s\n" "$1" >&2; }

backup_and_link() {
  local src="$1"
  local dest="$2"

  if [[ ! -e "$src" ]]; then
    warn "Missing in repo: $src (skipping)"
    return 0
  fi

  if [[ -e "$dest" && ! -L "$dest" ]]; then
    info "Backing up $dest"
    mv "$dest" "$dest.bak.$(date +%Y%m%d%H%M%S)"
  fi

  if [[ -L "$dest" ]]; then
    rm "$dest"
  fi

  mkdir -p "$(dirname "$dest")"
  info "Linking $src -> $dest"
  ln -sf "$src" "$dest"
}

info "Linking extras from: $DOTFILES_DIR/extras"

# Home dotfiles
backup_and_link "$DOTFILES_DIR/extras/home/.gitignore_global" "$HOME/.gitignore_global"
backup_and_link "$DOTFILES_DIR/extras/home/.ripgreprc" "$HOME/.ripgreprc"
backup_and_link "$DOTFILES_DIR/extras/home/.editorconfig" "$HOME/.editorconfig"
backup_and_link "$DOTFILES_DIR/extras/home/.tool-versions" "$HOME/.tool-versions"
backup_and_link "$DOTFILES_DIR/extras/home/.npmrc" "$HOME/.npmrc"
backup_and_link "$DOTFILES_DIR/extras/home/.asdfrc" "$HOME/.asdfrc"

# Warp Terminal (minimal)
backup_and_link "$DOTFILES_DIR/extras/home/.warp/settings.yaml" "$HOME/.warp/settings.yaml"
backup_and_link "$DOTFILES_DIR/extras/home/.warp/themes" "$HOME/.warp/themes"
backup_and_link "$DOTFILES_DIR/extras/home/.warp/launch_configurations" "$HOME/.warp/launch_configurations"

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
backup_and_link "$DOTFILES_DIR/extras/local/share/warp-terminal/launch_configurations" "$XDG_DATA_HOME/warp-terminal/launch_configurations"

# XDG configs
mkdir -p "$HOME/.config"
backup_and_link "$DOTFILES_DIR/extras/config/ghostty" "$HOME/.config/ghostty"
backup_and_link "$DOTFILES_DIR/extras/config/kitty" "$HOME/.config/kitty"
backup_and_link "$DOTFILES_DIR/extras/config/alacritty" "$HOME/.config/alacritty"
backup_and_link "$DOTFILES_DIR/extras/config/wezterm" "$HOME/.config/wezterm"
backup_and_link "$DOTFILES_DIR/extras/config/helix" "$HOME/.config/helix"
backup_and_link "$DOTFILES_DIR/extras/config/bat" "$HOME/.config/bat"
backup_and_link "$DOTFILES_DIR/extras/config/fd" "$HOME/.config/fd"
backup_and_link "$DOTFILES_DIR/extras/config/ripgrep" "$HOME/.config/ripgrep"

# Arch/Omarchy-ish (will just skip on macOS if not captured)
backup_and_link "$DOTFILES_DIR/extras/config/hypr" "$HOME/.config/hypr"
backup_and_link "$DOTFILES_DIR/extras/config/waybar" "$HOME/.config/waybar"
backup_and_link "$DOTFILES_DIR/extras/config/rofi" "$HOME/.config/rofi"
backup_and_link "$DOTFILES_DIR/extras/config/swaync" "$HOME/.config/swaync"
backup_and_link "$DOTFILES_DIR/extras/config/dunst" "$HOME/.config/dunst"

info "Done!"

