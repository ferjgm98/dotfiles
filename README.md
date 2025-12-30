# Dotfiles

Cross-platform dotfiles for macOS and Arch Linux.

## What's included

- **zsh** - Shell config with Antidote plugin manager, Starship prompt
- **tmux** - Terminal multiplexer with Tokyo Night theme, sesh integration
- **neovim** - LazyVim configuration
- **starship** - Cross-shell prompt with Nerd Font icons
- **git** - Global git configuration
- **Brewfile** - All Homebrew packages (macOS only)

## Quick Start (macOS)

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles

# Run the bootstrap script
chmod +x ~/dotfiles/scripts/bootstrap-macos.sh
~/dotfiles/scripts/bootstrap-macos.sh
```

## Quick Start (Arch Linux)

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles

# Run the bootstrap script
chmod +x ~/dotfiles/scripts/bootstrap-arch.sh
~/dotfiles/scripts/bootstrap-arch.sh
```

## Manual Linking

If you just want to symlink the configs without installing packages:

```bash
chmod +x ~/dotfiles/scripts/link.sh
~/dotfiles/scripts/link.sh
```

## Tools & Dependencies

### Core (installed by bootstrap)
- zsh + antidote (plugin manager)
- tmux + tpm (plugin manager)  
- neovim + lazy.nvim
- starship (prompt)
- fzf, fd, bat, eza, zoxide, ripgrep

### Optional
- fnm (Node.js version manager)
- pyenv (Python version manager)
- 1password-cli (secrets management)
- docker

## Post-install

1. **Fonts**: Install a Nerd Font for icons
   ```bash
   # Arch
   yay -S ttf-jetbrains-mono-nerd
   ```

2. **Tmux plugins**: Open tmux and press `prefix + I`

3. **Node.js**: `fnm install --lts`

4. **Python**: `pyenv install 3.12`

## Secrets (1Password)

API keys are loaded on-demand using 1Password CLI:
```bash
secrets_on   # Load all API keys
secrets_off  # Unload all API keys
```

## Structure

```
dotfiles/
├── zsh/
│   ├── .zshrc
│   └── .zsh_plugins.txt
├── tmux/
│   └── .tmux.conf
├── nvim/
│   └── nvim/           # Full LazyVim config
├── starship/
│   └── starship.toml
├── scripts/
│   ├── bootstrap-arch.sh
│   ├── bootstrap-macos.sh
│   └── link.sh
├── Brewfile            # Homebrew packages (macOS)
├── .gitconfig
└── README.md
```

## Updating Brewfile

To update the Brewfile with your current packages:
```bash
brew bundle dump --file=~/dotfiles/Brewfile --force
```
