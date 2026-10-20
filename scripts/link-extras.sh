#!/usr/bin/env bash
set -euo pipefail

# Optional linking for extras/ (captured allowlist).
# This keeps the main install minimal, but lets you restore more of ~/ when you want.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

info() { printf "[INFO] %s\n" "$1"; }
warn() { printf "[WARN] %s\n" "$1" >&2; }
die() { printf "[ERROR] %s\n" "$1" >&2; exit 1; }

usage() {
  cat <<'EOF'
Usage: link-extras.sh [--dry-run] [--no-desktop]

Options:
  --dry-run     Show links without changing files.
  --no-desktop  Skip linking desktop/WM configs (hypr/waybar/rofi/swaync/dunst).
                Recommended on Omarchy unless extras were captured from that same Omarchy install.
EOF
}

DRY_RUN=0
NO_DESKTOP=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --no-desktop) NO_DESKTOP=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown argument: $1 (use --help)" ;;
  esac
done

source "$DOTFILES_DIR/scripts/link-common.sh"

link_optional() {
  if [[ -e "$1" ]]; then
    backup_and_link "$1" "$2"
  else
    warn "Missing in repo: $1 (skipping)"
  fi
}

info "Linking extras from: $DOTFILES_DIR/extras"

# Home dotfiles
link_optional "$DOTFILES_DIR/extras/home/.gitignore_global" "$HOME/.gitignore_global"
link_optional "$DOTFILES_DIR/extras/home/.ripgreprc" "$HOME/.ripgreprc"
link_optional "$DOTFILES_DIR/extras/home/.editorconfig" "$HOME/.editorconfig"
link_optional "$DOTFILES_DIR/extras/home/.tool-versions" "$HOME/.tool-versions"
link_optional "$DOTFILES_DIR/extras/home/.npmrc" "$HOME/.npmrc"
link_optional "$DOTFILES_DIR/extras/home/.asdfrc" "$HOME/.asdfrc"

# Warp Terminal (minimal)
link_optional "$DOTFILES_DIR/extras/home/.warp/settings.yaml" "$HOME/.warp/settings.yaml"
link_optional "$DOTFILES_DIR/extras/home/.warp/themes" "$HOME/.warp/themes"
link_optional "$DOTFILES_DIR/extras/home/.warp/launch_configurations" "$HOME/.warp/launch_configurations"

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
link_optional "$DOTFILES_DIR/extras/local/share/warp-terminal/launch_configurations" "$XDG_DATA_HOME/warp-terminal/launch_configurations"

# XDG configs
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
link_optional "$DOTFILES_DIR/extras/config/kitty" "$CONFIG_DIR/kitty"
link_optional "$DOTFILES_DIR/extras/config/alacritty" "$CONFIG_DIR/alacritty"
link_optional "$DOTFILES_DIR/extras/config/wezterm" "$CONFIG_DIR/wezterm"
link_optional "$DOTFILES_DIR/extras/config/helix" "$CONFIG_DIR/helix"
link_optional "$DOTFILES_DIR/extras/config/bat" "$CONFIG_DIR/bat"
link_optional "$DOTFILES_DIR/extras/config/fd" "$CONFIG_DIR/fd"
link_optional "$DOTFILES_DIR/extras/config/ripgrep" "$CONFIG_DIR/ripgrep"

# Arch/Omarchy-ish (will just skip on macOS if not captured)
if [[ "$NO_DESKTOP" -eq 1 ]]; then
  info "Skipping desktop/WM configs (--no-desktop)"
else
  link_optional "$DOTFILES_DIR/extras/config/hypr" "$CONFIG_DIR/hypr"
  link_optional "$DOTFILES_DIR/extras/config/waybar" "$CONFIG_DIR/waybar"
  link_optional "$DOTFILES_DIR/extras/config/rofi" "$CONFIG_DIR/rofi"
  link_optional "$DOTFILES_DIR/extras/config/swaync" "$CONFIG_DIR/swaync"
  link_optional "$DOTFILES_DIR/extras/config/dunst" "$CONFIG_DIR/dunst"
fi

info "Done!"

