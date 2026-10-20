# Dotfiles

Cross-platform dotfiles for macOS and Arch Linux.

## What's included

- **zsh** - Shell config with Antidote plugin manager, Starship prompt
- **tmux** - Terminal multiplexer with Gruvbox theme, sesh integration
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
~/dotfiles/scripts/link.sh --dry-run
~/dotfiles/scripts/link.sh
```

Existing files, directories, and unrelated symlinks are moved to timestamped
backups beside their original paths. Repeated runs leave correct links alone.
Both bootstrap scripts use this same linker.

Shell files respect `ZDOTDIR`; application configs respect `XDG_CONFIG_HOME`.
The defaults are `~` and `~/.config`.

## Check the setup

```bash
bash ~/dotfiles/scripts/doctor.sh
bash ~/dotfiles/scripts/check.sh
```

`doctor.sh` reports config drift, broken links, and missing core tools without
changing files. It exits with status 1 when something needs attention.
`check.sh` checks shell syntax and runs regression tests in temporary directories.
It requires Bash, Zsh, Python 3, and rsync.

## Machine-specific shell settings

Put local aliases, paths, and settings in `~/.zshrc.local`, or
`$ZDOTDIR/.zshrc.local` when using `ZDOTDIR`. The repo shell config loads this
file before the Kiro post hook. Keep credentials in 1Password.

## Backup your current ~/ setup into this repo (capture)

If you already have a working setup in your home directory and want to **copy it into this repo** (first-time backup):

```bash
chmod +x ~/dotfiles/scripts/capture.sh
~/dotfiles/scripts/capture.sh
```

By default, capture also collects an allowlist of extra configs into `extras/`
and skips missing sources. This includes Ghostty and Warp settings. Review the
contents before committing, since even terminal and shell configs can contain
credentials. `.npmrc` is excluded because it can contain registry tokens.
Preview the source and destination paths without changing files:

```bash
~/dotfiles/scripts/capture.sh --dry-run
```

Existing files and directories require confirmation. Without a terminal,
capture skips existing destinations unless you pass `--force`. Sources already
linked to their repo destination are skipped. File symlinks are copied as
contents; directory capture omits symlinks that point outside the copied tree.
Neovim's `lua/plugins` definitions are included.

To mirror directories, removing destination files absent from the source:

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

On **Omarchy**, it’s usually safer to restore just terminal/CLI extras (Warp/Ghostty/etc) and avoid overwriting the desktop stack unless you know your `extras/` are compatible:

```bash
~/dotfiles/scripts/link-extras.sh --no-desktop
```

Add `--dry-run` to preview extra links without changing files.

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
