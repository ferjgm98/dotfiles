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

info "Starting dotfiles bootstrap for macOS..."
info "Dotfiles directory: $DOTFILES_DIR"

# Check if running on macOS
if [[ "$(uname -s)" != "Darwin" ]]; then
    error "This script is intended for macOS"
fi

# Install Xcode Command Line Tools if not present
if ! xcode-select -p &> /dev/null; then
    info "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "Press any key after Xcode CLT installation completes..."
    read -n 1
fi

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add brew to PATH for Apple Silicon
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

# Install packages from Brewfile
info "Installing packages from Brewfile..."
brew bundle install --file="$DOTFILES_DIR/Brewfile" --no-lock || warn "Some packages may have failed to install"

# Set zsh as default shell
if [[ "$SHELL" != */zsh ]]; then
    info "Setting zsh as default shell..."
    chsh -s "$(which zsh)"
fi

# Create necessary directories
info "Creating directories..."
mkdir -p ~/.config
mkdir -p ~/.local/bin
mkdir -p ~/Library/pnpm
mkdir -p ~/.cache/oh-my-zsh/completions

# Symlink dotfiles
info "Creating symlinks..."

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

info "=========================================="
info "Bootstrap complete!"
info "=========================================="
echo ""
info "Next steps:"
echo "  1. Restart your terminal (or run: source ~/.zshrc)"
echo "  2. Open tmux and press 'prefix + I' to install tmux plugins"
echo "  3. Open nvim - plugins will auto-install via lazy.nvim"
echo "  4. Run 'fnm install --lts' to install Node.js"
echo "  5. Run 'pyenv install 3.12' to install Python"
echo ""
