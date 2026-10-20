# Dotfiles

Cross-platform dotfiles for macOS and Arch Linux.

## What's included

- **zsh** - Shell config with Antidote plugin manager, Starship prompt
- **Ghostty** - Shared terminal appearance for Ghostty and cmux
- **cmux** - macOS terminal workspace settings
- **Herdr** - Persistent workspaces for coding agents
- **tmux** - Optional fallback with Gruvbox theme and sesh integration
- **neovim** - LazyVim configuration
- **starship** - Cross-shell prompt with Nerd Font icons
- **git** - Global git configuration
- **Brewfile** - All Homebrew packages (macOS only)

## Quick start (macOS)

```bash
# Clone the repo
git clone https://github.com/ferjgm98/dotfiles.git ~/dotfiles

# Run the bootstrap script
chmod +x ~/dotfiles/scripts/bootstrap-macos.sh
~/dotfiles/scripts/bootstrap-macos.sh
```

## Quick start (Arch Linux)

```bash
# Clone the repo
git clone https://github.com/ferjgm98/dotfiles.git ~/dotfiles

# Run the bootstrap script
chmod +x ~/dotfiles/scripts/bootstrap-arch.sh
~/dotfiles/scripts/bootstrap-arch.sh
```

Note: the Arch bootstrap will use your existing AUR helper if available (`yay` or `paru`). If neither is installed, it will install `yay`.

## Terminal workflow

Open Ghostty or cmux, then run `herdr` when you want persistent agent workspaces.
Herdr is launched manually; shell startup does not attach or start a session.

- `ghostty/config` preserves Gruvbox Dark Hard, MonoLisaCode Nerd Font at size 14,
  and left Option as Alt on macOS. Install that font on a new machine or select
  an installed font. The linker uses the same file for the XDG location and the
  native macOS Ghostty location, which cmux also reads.
- `cmux/cmux.json` is the app settings file for macOS. It currently has no
  overrides, so cmux uses its GUI preferences. Those preferences remain local;
  add explicit JSON settings here when you want to share them across machines.
- `herdr/config.toml` preserves the current theme, keys, notifications, and
  session restore preferences. `Ctrl+A` is the prefix; `prefix+-` and `prefix+v`
  split panes, `prefix+c` creates a tab, and `Alt+J/K` switches workspaces.
  Bare `Ctrl+H/J/K/L` also switches Herdr panes, including while Neovim is active.
  Remove those bare chords from the config if you prefer Neovim to handle them.

See the [Herdr docs](https://herdr.dev/docs/configuration/) and
[cmux configuration docs](https://cmux.com/docs/configuration).

## Optional tmux setup

The default bootstrap and linker leave tmux alone. To install tmux, sesh, TPM,
and link their configs, use the flag for your platform:

```bash
~/dotfiles/scripts/bootstrap-macos.sh --with-tmux
# Or on Arch:
~/dotfiles/scripts/bootstrap-arch.sh --with-tmux
```

Existing tmux installations and links continue to work. Neovim loads its tmux
navigation plugin only inside tmux.

## Manual linking

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
The defaults are `~` and `~/.config`. `HERDR_CONFIG_PATH` can override the
Herdr file location. Add `--with-tmux` to link the optional tmux configs.

## Check the setup

```bash
bash ~/dotfiles/scripts/doctor.sh
bash ~/dotfiles/scripts/check.sh
```

`doctor.sh` reports config drift, broken links, and missing core tools without
changing files. It exits with status 1 when something needs attention.
Use `doctor.sh --with-tmux` to include the optional tmux checks.
`check.sh` checks shell syntax and runs regression tests in temporary directories.
It requires Bash, Zsh, Python 3, and rsync.

The offline plugin integration test also needs existing checkouts. Set
`ANTIDOTE_TEST_SOURCE` to `antidote.zsh`, `ANTIDOTE_TEST_CACHE` to the directory
containing the `owner/repo` plugin directories, and `EZ_COMPINIT_TEST_DIR` to the
ez-compinit checkout. Without these paths, that test is skipped. The test checks
both a fresh completion cache and a cached startup without downloading plugins.

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
and skips missing sources. This includes Warp settings. Ghostty, Herdr, and
macOS cmux configs are part of the core capture. Review the
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
Neovim's `lua/plugins` definitions are included. rsync reports skipped external
symlinks. Even with `--delete`, an old destination file at a skipped link
can remain; review those messages before treating the capture as a mirror.

To mirror directories, removing destination files absent from the source:

```bash
~/dotfiles/scripts/capture.sh --delete
```

This copies:

- `~/.zshrc` → `zsh/.zshrc`
- `~/.zsh_plugins.txt` → `zsh/.zsh_plugins.txt`
- `~/.config/ghostty/config` → `ghostty/config`, with the native macOS path as a fallback
- `~/.config/herdr/config.toml` → `herdr/config.toml`
- `~/.config/cmux/cmux.json` → `cmux/cmux.json` on macOS, with legacy `settings.json` as a fallback
- `~/.tmux.conf` → `tmux/.tmux.conf` when present
- `~/.tmux/scripts/git-status.sh` → `tmux/scripts/git-status.sh`
- `~/.gitconfig` → `.gitconfig`
- `~/.config/starship.toml` → `starship/starship.toml`
- `~/.config/nvim/` → `nvim/nvim/`

Only the named terminal config files are copied. Herdr and cmux sessions, logs,
and sockets stay local.

## Restore extra configs (optional)

If you captured `extras/` and want to symlink them into place:

```bash
chmod +x ~/dotfiles/scripts/link-extras.sh
~/dotfiles/scripts/link-extras.sh
```

On **Omarchy**, it’s usually safer to restore just terminal/CLI extras (Warp/Kitty/etc) and avoid overwriting the desktop stack unless you know your `extras/` are compatible:

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

## Tools and dependencies

### Core (installed by bootstrap)

- zsh + antidote (plugin manager)
- Ghostty + Herdr
- cmux on macOS
- neovim + lazy.nvim
- starship (prompt)
- fzf, fd, bat, eza, zoxide, ripgrep

### Optional

- tmux + TPM + sesh, via `--with-tmux`
- fnm (Node.js version manager)
- pyenv (Python version manager)
- 1password-cli (secrets management)
- docker

The macOS bootstrap selects stable Neovim with Bob when no Neovim installation
is present. GitHub CLI is installed on both platforms, and Git resolves it through
`PATH`. Python 3.9 is excluded from the Homebrew bundle; use pyenv if a project
requires that legacy version.

Zsh uses `mattmc3/ez-compinit` to queue plugin completion definitions until all
plugin completion paths are loaded. Antidote downloads it on the next shell start.

## Post-install

1. **Fonts**: Install a Nerd Font for icons

   ```bash
   # Arch
   yay -S ttf-jetbrains-mono-nerd
   ```

2. **Terminals**: Open Ghostty or cmux and run `herdr`. If you opted into tmux,
   open tmux and press `prefix + I` to install its plugins.

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
├── ghostty/
│   └── config
├── cmux/
│   └── cmux.json
├── herdr/
│   └── config.toml
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
├── Brewfile            # Default Homebrew packages (macOS)
├── Brewfile.tmux       # Optional tmux and sesh
├── .gitconfig
└── README.md
```

## Updating Brewfile

Dump installed packages to a separate file and review the additions before
editing the tracked Brewfiles. Keep tmux and sesh in `Brewfile.tmux`:

```bash
brew bundle dump --file=/tmp/Brewfile.installed --force
diff -u ~/dotfiles/Brewfile /tmp/Brewfile.installed
```
