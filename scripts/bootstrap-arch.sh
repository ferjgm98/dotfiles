#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

WITH_TMUX=0
WITH_DEV_TOOLS=1
while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-dev-tools) WITH_DEV_TOOLS=0 ;;
        --with-tmux) WITH_TMUX=1 ;;
        -h|--help) echo "Usage: $(basename "$0") [--with-tmux] [--skip-dev-tools]"; exit 0 ;;
        *) error "Unknown argument: $1" ;;
    esac
    shift
done

info "Starting dotfiles bootstrap for Arch Linux..."
info "Dotfiles directory: $DOTFILES_DIR"

# Check if running on Arch
if ! command -v pacman &> /dev/null; then
    error "This script is intended for Arch Linux (pacman not found)"
fi

# Pick an AUR helper (Omarchy often ships with paru)
if command -v yay &> /dev/null; then
    AUR_HELPER="yay"
elif command -v paru &> /dev/null; then
    AUR_HELPER="paru"
else
    AUR_HELPER=""
fi

# Install yay if not present
if [[ -z "${AUR_HELPER}" ]]; then
    info "Installing yay (AUR helper)..."
    sudo pacman -S --needed --noconfirm git base-devel
    YAY_TMP="$(mktemp -d)"
    cleanup() { rm -rf "$YAY_TMP"; }
    trap cleanup EXIT
    git clone https://aur.archlinux.org/yay.git "$YAY_TMP/yay"
    (cd "$YAY_TMP/yay" && makepkg -si --noconfirm)
    trap - EXIT
    cleanup
    AUR_HELPER="yay"
fi

# Install packages
info "Installing packages from pacman..."
sudo pacman -S --needed --noconfirm \
    zsh \
    ghostty \
    neovim \
    git \
    git-lfs \
    github-cli \
    base-devel \
    fzf \
    fd \
    bat \
    eza \
    zoxide \
    starship \
    ripgrep \
    docker \
    docker-compose \
    python \
    python-pip \
    uv \
    pyenv \
    nodejs \
    npm \
    unzip \
    wget \
    curl \
    bc

info "Installing packages from AUR..."
"$AUR_HELPER" -S --needed --noconfirm \
    fnm-bin \
    zsh-antidote \
    1password-cli || warn "Some AUR packages may have failed"

if [[ "$WITH_TMUX" -eq 1 ]]; then
    sudo pacman -S --needed --noconfirm tmux
    "$AUR_HELPER" -S --needed --noconfirm sesh-bin
fi

if ! command -v herdr >/dev/null 2>&1 && [[ ! -x "$HOME/.local/bin/herdr" ]]; then
    info "Installing Herdr..."
    curl -fsSL https://herdr.dev/install.sh | sh
fi

# Set zsh as default shell
if [[ "$SHELL" != */zsh ]]; then
    info "Setting zsh as default shell..."
    ZSH_BIN="$(command -v zsh)"
    if [[ -z "$ZSH_BIN" ]]; then
        error "zsh not found"
    fi
    if ! grep -qxF "$ZSH_BIN" /etc/shells; then
        warn "$ZSH_BIN not in /etc/shells; adding (requires sudo)..."
        echo "$ZSH_BIN" | sudo tee -a /etc/shells >/dev/null
    fi
    chsh -s "$ZSH_BIN"
fi

# Create necessary directories
info "Creating directories..."
mkdir -p ~/.config
mkdir -p ~/.local/bin
mkdir -p ~/.local/share/pnpm
mkdir -p ~/.cache/oh-my-zsh/completions

# Use the same backup and linking rules as a manual install.
if [[ "$WITH_TMUX" -eq 1 ]]; then
    bash "$DOTFILES_DIR/scripts/link.sh" --with-tmux
else
    bash "$DOTFILES_DIR/scripts/link.sh"
fi

# Install tmux plugin manager
if [[ "$WITH_TMUX" -eq 1 && ! -d ~/.tmux/plugins/tpm ]]; then
    info "Installing tmux plugin manager (TPM)..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

if [[ "$WITH_DEV_TOOLS" -eq 1 ]]; then
    bash "$DOTFILES_DIR/scripts/install-dev-tools.sh"
else
    # Install bun
    if ! command -v bun &> /dev/null; then
        info "Installing bun..."
        curl -fsSL https://bun.sh/install | bash
    fi

    # Install pnpm
    if ! command -v pnpm &> /dev/null; then
        info "Installing pnpm..."
        curl -fsSL https://get.pnpm.io/install.sh | sh -
    fi
fi

# Enable docker service
info "Enabling docker service..."
sudo systemctl enable --now docker.service
sudo usermod -aG docker "$USER" || true

info "=========================================="
info "Bootstrap complete!"
info "=========================================="
echo ""
info "Next steps:"
echo "  1. Log out and log back in (for zsh and docker group)"
echo "  2. Open Ghostty, then run herdr for persistent workspaces"
if [[ "$WITH_TMUX" -eq 1 ]]; then
    echo "     Optional tmux: press 'prefix + I' to install plugins"
fi
echo "  3. Open nvim - plugins will auto-install via lazy.nvim"
echo "  4. Sign in to the coding tools you use; project runtimes can be installed with fnm/pyenv"
echo "  5. Run 'pyenv install 3.12' to install Python"
echo ""
warn "If icons don't display correctly, install a Nerd Font:"
echo "  yay -S ttf-jetbrains-mono-nerd"
echo ""
