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
git clone https://github.com/ferjgm98/dotfiles.git ~/dotfiles

# Run the bootstrap script
chmod +x ~/dotfiles/scripts/bootstrap-macos.sh
~/dotfiles/scripts/bootstrap-macos.sh
```

## Quick Start (Arch Linux)

```bash
# Clone the repo
git clone https://github.com/ferjgm98/dotfiles.git ~/dotfiles

# Run the bootstrap script
chmod +x ~/dotfiles/scripts/bootstrap-arch.sh
~/dotfiles/scripts/bootstrap-arch.sh
```

Note: the Arch bootstrap will use your existing AUR helper if available (`yay` or `paru`). If neither is installed, it will install `yay`.

## Manual Linking

If you just want to symlink the configs without installing packages:

```bash
chmod +x ~/dotfiles/scripts/link.sh
~/dotfiles/scripts/link.sh
```

## Backup your current ~/ setup into this repo (capture)

If you already have a working setup in your home directory and want to **copy it into this repo** (first-time backup):

```bash
chmod +x ~/dotfiles/scripts/capture.sh
~/dotfiles/scripts/capture.sh
```

By default, capture also collects a **curated allowlist** of extra, generally-safe configs into `extras/` (it will skip anything missing). This includes **Ghostty** (`~/.config/ghostty`) and **Warp** (minimal config from `~/.warp/`). You can preview with:

```bash
~/dotfiles/scripts/capture.sh --dry-run
```

To mirror directories (destructive sync via `rsync --delete`), run:

```bash
~/dotfiles/scripts/capture.sh --delete
```

This copies:

- `~/.zshrc` → `zsh/.zshrc`
- `~/.zsh_plugins.txt` → `zsh/.zsh_plugins.txt`
- `~/.tmux.conf` → `tmux/.tmux.conf`
- `~/.gitconfig` → `.gitconfig`
- `~/.config/starship.toml` → `starship/starship.toml`
- `~/.config/nvim/` → `nvim/nvim/`

## Restore extra configs (optional)

If you captured `extras/` and want to symlink them into place:

```bash
chmod +x ~/dotfiles/scripts/link-extras.sh
~/dotfiles/scripts/link-extras.sh
```

## What NOT to commit

Avoid committing anything that can compromise accounts or machines:

- `~/.ssh/` (private keys)
- `~/.gnupg/` (GPG keys)
- `~/.aws/`, `~/.kube/` (cloud creds)
- `.env*` files with API keys
- `~/Library/Keychains/` and most of `~/Library/Application Support/` (state + secrets)

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
