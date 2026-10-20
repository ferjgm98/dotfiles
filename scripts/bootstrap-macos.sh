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

info "Starting dotfiles bootstrap for macOS..."
info "Dotfiles directory: $DOTFILES_DIR"

# Check if running on macOS
if [[ "$(uname -s)" != "Darwin" ]]; then
    error "This script is intended for macOS"
fi

# Install Xcode Command Line Tools if not present
if ! xcode-select -p &> /dev/null; then
    info "Installing Xcode Command Line Tools..."
    xcode-select --install || true
    if [[ -t 0 ]]; then
        warn "Finish the Xcode CLT installer dialog, then press any key to continue..."
        read -n 1
    else
        error "Xcode CLT install requires interaction. Please complete it, then re-run this script."
    fi
fi

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to PATH (Apple Silicon or Intel)
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# Install packages from Brewfile
info "Installing packages from Brewfile..."
brew bundle install --file="$DOTFILES_DIR/Brewfile" || error "Package installation failed. Fix the errors above and rerun bootstrap."
if [[ "$WITH_TMUX" -eq 1 ]]; then
    brew bundle install --file="$DOTFILES_DIR/Brewfile.tmux"
fi

# Bob installs the manager; select Neovim only when it is not installed yet.
if ! command -v nvim >/dev/null 2>&1 && [[ ! -x "$HOME/.local/share/bob/nvim-bin/nvim" ]]; then
    info "Installing stable Neovim with Bob..."
    bob use stable
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
mkdir -p ~/Library/pnpm
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

info "=========================================="
info "Bootstrap complete!"
info "=========================================="
echo ""
info "Next steps:"
echo "  1. Restart your terminal (or run: source ~/.zshrc)"
echo "  2. Open Ghostty or cmux, then run herdr for persistent workspaces"
if [[ "$WITH_TMUX" -eq 1 ]]; then
    echo "     Optional tmux: press 'prefix + I' to install plugins"
fi
echo "  3. Open nvim - plugins will auto-install via lazy.nvim"
echo "  4. Sign in to the coding tools you use; project runtimes can be installed with fnm/pyenv"
echo "  5. Run 'pyenv install 3.12' to install Python"
echo ""
