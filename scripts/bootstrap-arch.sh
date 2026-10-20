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
    tmux \
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
    1password-cli \
    sesh-bin || warn "Some AUR packages may have failed"

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
bash "$DOTFILES_DIR/scripts/link.sh"

# Install tmux plugin manager
if [[ ! -d ~/.tmux/plugins/tpm ]]; then
    info "Installing tmux plugin manager (TPM)..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

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
echo "  2. Open tmux and press 'prefix + I' to install tmux plugins"
echo "  3. Open nvim - plugins will auto-install via lazy.nvim"
echo "  4. Run 'fnm install --lts' to install Node.js"
echo "  5. Run 'pyenv install 3.12' to install Python"
echo ""
warn "If icons don't display correctly, install a Nerd Font:"
echo "  yay -S ttf-jetbrains-mono-nerd"
echo ""
