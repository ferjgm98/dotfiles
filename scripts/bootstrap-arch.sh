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

# Install yay if not present
if ! command -v yay &> /dev/null; then
    info "Installing yay (AUR helper)..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
    rm -rf /tmp/yay
fi

# Install packages
info "Installing packages from pacman..."
sudo pacman -S --needed --noconfirm \
    zsh \
    tmux \
    neovim \
    git \
    git-lfs \
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
yay -S --needed --noconfirm \
    fnm-bin \
    zsh-antidote \
    1password-cli \
    sesh-bin || warn "Some AUR packages may have failed"

# Set zsh as default shell
if [[ "$SHELL" != */zsh ]]; then
    info "Setting zsh as default shell..."
    chsh -s "$(which zsh)"
fi

# Create necessary directories
info "Creating directories..."
mkdir -p ~/.config
mkdir -p ~/.local/bin
mkdir -p ~/.local/share/pnpm
mkdir -p ~/.cache/oh-my-zsh/completions

# Symlink dotfiles
info "Creating symlinks..."

# Backup existing files
backup_if_exists() {
    if [[ -e "$1" && ! -L "$1" ]]; then
        warn "Backing up existing $1 to $1.bak"
        mv "$1" "$1.bak.$(date +%Y%m%d%H%M%S)"
    fi
}

# Zsh
backup_if_exists ~/.zshrc
backup_if_exists ~/.zsh_plugins.txt
ln -sf "$DOTFILES_DIR/zsh/.zshrc" ~/.zshrc
ln -sf "$DOTFILES_DIR/zsh/.zsh_plugins.txt" ~/.zsh_plugins.txt

# Tmux
backup_if_exists ~/.tmux.conf
ln -sf "$DOTFILES_DIR/tmux/.tmux.conf" ~/.tmux.conf

# Git
backup_if_exists ~/.gitconfig
ln -sf "$DOTFILES_DIR/.gitconfig" ~/.gitconfig

# Starship
backup_if_exists ~/.config/starship.toml
ln -sf "$DOTFILES_DIR/starship/starship.toml" ~/.config/starship.toml

# Neovim
backup_if_exists ~/.config/nvim
ln -sf "$DOTFILES_DIR/nvim/nvim" ~/.config/nvim

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
