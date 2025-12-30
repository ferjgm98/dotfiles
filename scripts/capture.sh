#!/usr/bin/env bash
set -euo pipefail

# Capture current HOME configs into this repo (for initial backup / migration).
# This copies files/directories into the repo; it does NOT symlink.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

info() { printf "[INFO] %s\n" "$1"; }
warn() { printf "[WARN] %s\n" "$1" >&2; }
die() { printf "[ERROR] %s\n" "$1" >&2; exit 1; }

usage() {
  cat <<'EOF'
Usage: capture.sh [--dry-run] [--force] [--with-extras|--no-extras] [--delete]

Captures your current HOME configs into this repo.

Options:
  --dry-run     Show what would be copied (no changes)
  --force       Don't prompt before overwriting repo files (still safe-guarded)
  --with-extras Capture a curated allowlist of additional configs into extras/ (default)
  --no-extras   Skip capturing extras/
  --delete      Mirror directories (rsync --delete). Default is non-destructive sync.
EOF
}

DRY_RUN=0
FORCE=0
WITH_EXTRAS=1
RSYNC_DELETE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --force) FORCE=1; shift ;;
    --with-extras) WITH_EXTRAS=1; shift ;;
    --no-extras) WITH_EXTRAS=0; shift ;;
    --delete) RSYNC_DELETE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown argument: $1 (use --help)" ;;
  esac
done

if ! command -v rsync >/dev/null 2>&1; then
  die "rsync not found. Install it and re-run."
fi

confirm_overwrite() {
  local dest="$1"
  if [[ "$FORCE" -eq 1 || "$DRY_RUN" -eq 1 ]]; then
    return 0
  fi
  if [[ -e "$dest" && -t 0 ]]; then
    warn "Destination exists: $dest"
    printf "Overwrite? [y/N] "
    read -r ans
    [[ "$ans" == "y" || "$ans" == "Y" ]]
  else
    return 0
  fi
}

copy_file() {
  local src="$1"
  local dest="$2"

  if [[ ! -e "$src" ]]; then
    warn "Missing: $src (skipping)"
    return 0
  fi

  if [[ -e "$dest" ]]; then
    confirm_overwrite "$dest" || { warn "Skipping (kept existing): $dest"; return 0; }
  fi

  mkdir -p "$(dirname "$dest")"
  info "Copying file: $src -> $dest"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    return 0
  fi
  cp -a "$src" "$dest"
}

copy_dir() {
  local src="$1"
  local dest="$2"

  if [[ ! -d "$src" ]]; then
    warn "Missing dir: $src (skipping)"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  info "Syncing dir: $src -> $dest"

  local -a rsync_args
  rsync_args=(-a)
  [[ "$DRY_RUN" -eq 1 ]] && rsync_args+=(-n)
  [[ "$RSYNC_DELETE" -eq 1 ]] && rsync_args+=(--delete)

  # Excludes: never capture caches/secrets/state here (keep repos clean + safe)
  rsync_args+=(
    --exclude ".git"
    --exclude ".DS_Store"
    --exclude ".zcompdump*"
    --exclude "node_modules"
    --exclude ".venv"
    --exclude "__pycache__"
    --exclude ".mypy_cache"
    --exclude ".pytest_cache"
    --exclude ".ruff_cache"
    --exclude ".cache"
    --exclude "plugin"
    --exclude "plugins"
  )

  rsync "${rsync_args[@]}" \
    "$src"/ "$dest"/
}

info "Capturing dotfiles into: $DOTFILES_DIR"

# Shell
copy_file "$HOME/.zshrc" "$DOTFILES_DIR/zsh/.zshrc"
copy_file "$HOME/.zsh_plugins.txt" "$DOTFILES_DIR/zsh/.zsh_plugins.txt"

# Tmux
copy_file "$HOME/.tmux.conf" "$DOTFILES_DIR/tmux/.tmux.conf"

# Git
copy_file "$HOME/.gitconfig" "$DOTFILES_DIR/.gitconfig"

# Common, safe-to-version CLI dotfiles (optional; placed in extras/)
if [[ "$WITH_EXTRAS" -eq 1 ]]; then
  info "Capturing curated extras into: $DOTFILES_DIR/extras"

  # HOME dotfiles (safe allowlist)
  copy_file "$HOME/.gitignore_global" "$DOTFILES_DIR/extras/home/.gitignore_global"
  copy_file "$HOME/.ripgreprc" "$DOTFILES_DIR/extras/home/.ripgreprc"
  copy_file "$HOME/.editorconfig" "$DOTFILES_DIR/extras/home/.editorconfig"
  copy_file "$HOME/.tool-versions" "$DOTFILES_DIR/extras/home/.tool-versions"
  copy_file "$HOME/.npmrc" "$DOTFILES_DIR/extras/home/.npmrc"
  copy_file "$HOME/.asdfrc" "$DOTFILES_DIR/extras/home/.asdfrc"

  # XDG configs (safe allowlist)
  copy_dir "$HOME/.config/ghostty" "$DOTFILES_DIR/extras/config/ghostty"
  # Warp Terminal (keep minimal + portable: settings, themes, launch configs)
  copy_file "$HOME/.warp/settings.yaml" "$DOTFILES_DIR/extras/home/.warp/settings.yaml"
  copy_dir "$HOME/.warp/themes" "$DOTFILES_DIR/extras/home/.warp/themes"
  copy_dir "$HOME/.warp/launch_configurations" "$DOTFILES_DIR/extras/home/.warp/launch_configurations"

  # Warp (Linux data dir; Warp for Linux stores some things under XDG_DATA_HOME)
  XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
  copy_dir "$XDG_DATA_HOME/warp-terminal/launch_configurations" "$DOTFILES_DIR/extras/local/share/warp-terminal/launch_configurations"

  copy_dir "$HOME/.config/kitty" "$DOTFILES_DIR/extras/config/kitty"
  copy_dir "$HOME/.config/alacritty" "$DOTFILES_DIR/extras/config/alacritty"
  copy_dir "$HOME/.config/wezterm" "$DOTFILES_DIR/extras/config/wezterm"
  copy_dir "$HOME/.config/helix" "$DOTFILES_DIR/extras/config/helix"
  copy_dir "$HOME/.config/bat" "$DOTFILES_DIR/extras/config/bat"
  copy_dir "$HOME/.config/fd" "$DOTFILES_DIR/extras/config/fd"
  copy_dir "$HOME/.config/ripgrep" "$DOTFILES_DIR/extras/config/ripgrep"

  # Arch/Omarchy-ish (if present; harmless on macOS)
  copy_dir "$HOME/.config/hypr" "$DOTFILES_DIR/extras/config/hypr"
  copy_dir "$HOME/.config/waybar" "$DOTFILES_DIR/extras/config/waybar"
  copy_dir "$HOME/.config/rofi" "$DOTFILES_DIR/extras/config/rofi"
  copy_dir "$HOME/.config/swaync" "$DOTFILES_DIR/extras/config/swaync"
  copy_dir "$HOME/.config/dunst" "$DOTFILES_DIR/extras/config/dunst"
fi

# Starship
copy_file "$HOME/.config/starship.toml" "$DOTFILES_DIR/starship/starship.toml"

# Neovim (repo expects nested nvim/nvim)
copy_dir "$HOME/.config/nvim" "$DOTFILES_DIR/nvim/nvim"

info "Done. Review changes, then commit."

