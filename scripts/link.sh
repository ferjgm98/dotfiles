#!/usr/bin/env bash
set -euo pipefail

# Simple symlink script (for manual linking without full bootstrap)

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Linking dotfiles from: $DOTFILES_DIR"

backup_and_link() {
    local src="$1"
    local dest="$2"
    
    if [[ -e "$dest" && ! -L "$dest" ]]; then
        echo "Backing up $dest"
        mv "$dest" "$dest.bak.$(date +%Y%m%d%H%M%S)"
    fi
    
    if [[ -L "$dest" ]]; then
        rm "$dest"
    fi
    
    echo "Linking $src -> $dest"
    ln -sf "$src" "$dest"
}

mkdir -p ~/.config

backup_and_link "$DOTFILES_DIR/zsh/.zshrc" ~/.zshrc
backup_and_link "$DOTFILES_DIR/zsh/.zsh_plugins.txt" ~/.zsh_plugins.txt
backup_and_link "$DOTFILES_DIR/tmux/.tmux.conf" ~/.tmux.conf
backup_and_link "$DOTFILES_DIR/.gitconfig" ~/.gitconfig
backup_and_link "$DOTFILES_DIR/starship/starship.toml" ~/.config/starship.toml
backup_and_link "$DOTFILES_DIR/nvim/nvim" ~/.config/nvim

echo "Done!"
