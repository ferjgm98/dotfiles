# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"

# Cross-platform .zshrc (macOS + Arch Linux)

# OS detection
case "$(uname -s)" in
  Darwin) OS="macos" ;;
  Linux)  OS="linux" ;;
  *)      OS="unknown" ;;
esac

# Environment
export EDITOR="nvim"
export FORGE_EDITOR="nvim"
export CLAUDE_CODE_NO_FLICKER=1
export PACKAGE_PROJECT_ID=70576898
export BUN_INSTALL="$HOME/.bun"

# Dedupe PATH automatically, no matter how many times installers re-add entries
typeset -U path PATH

# PATH (single source of truth)
# Nonexistent dirs are harmless; typeset -U above removes duplicates.
if [[ "$OS" == "macos" ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
  path=(
    "$HOME/.local/bin"
    "$HOME/.grok/bin"
    "$HOME/.local/share/bob/nvim-bin"
    /Applications/Kiro\ CLI.app/Contents/MacOS(N-/)
    /Applications/cmux.app/Contents/Resources/bin(N-/)
    /Applications/Ghostty.app/Contents/MacOS(N-/)
    /opt/homebrew/bin(N-/)
    /opt/homebrew/sbin(N-/)
    /usr/local/bin(N-/)
    /usr/local/sbin(N-/)
    /opt/homebrew/opt/php@8.0/bin(N-/)
    /opt/homebrew/opt/php@8.0/sbin(N-/)
    /opt/homebrew/opt/postgresql@15/bin(N-/)
    /opt/homebrew/opt/openjdk@17/bin(N-/)
    "$PNPM_HOME"
    "$BUN_INSTALL/bin"
    "$HOME/.lmstudio/bin"
    "$HOME/.opencode/bin"
    "$HOME/.amp/bin"
    "$HOME/.antigravity/antigravity/bin"
    "$HOME/.antigravity-ide/antigravity-ide/bin"
    "$HOME/.codeium/windsurf/bin"
    "$HOME/.kimi-code/bin"
    $path
  )
  [[ -d "/opt/homebrew/opt/openjdk@17/include" ]] && export CPPFLAGS="-I/opt/homebrew/opt/openjdk@17/include"
else
  # Linux (Arch)
  export PNPM_HOME="$HOME/.local/share/pnpm"
  path=(
    "$HOME/.local/bin"
    "$HOME/.grok/bin"
    "$HOME/.amp/bin"
    "$HOME/.kimi-code/bin"
    "$PNPM_HOME"
    "$BUN_INSTALL/bin"
    "$HOME/.lmstudio/bin"
    "$HOME/.opencode/bin"
    /usr/local/bin
    $path
  )
fi
# Note: ~/.qoder/entry is added in ~/.zshenv so non-interactive shells get it too.

# History
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=100000
SAVEHIST=50000
setopt share_history        # share history between running shells
setopt extended_history     # timestamps + durations in saved history
setopt hist_ignore_dups     # ignore consecutive duplicates
setopt hist_ignore_space    # commands starting with a space aren't recorded
setopt hist_reduce_blanks   # strip redundant whitespace
setopt hist_verify          # verify !! expansions before running
setopt hist_find_no_dups    # skip duplicates in history search

# Options
setopt interactive_comments
setopt auto_cd              # type a directory name to cd into it
setopt auto_pushd pushd_ignore_dups pushdminus

# 1Password-backed env helpers (loads secrets only when you call secrets_on)
__OP_ENV_ID="avawumre6uqhofxaxhmbnafigy"
secrets_on() {
  (( $+commands[op] )) || { echo 'op not found' >&2; return 1; }
  local env_vars
  env_vars="$(op environment read "$__OP_ENV_ID")" || return
  eval "$env_vars"
}
secrets_off() {
  unset OPENAI_API_KEY ANTHROPIC_API_KEY OPENROUTER_API_KEY GROQ_API_KEY GEMINI_API_KEY MISTRAL_API_KEY PERPLEXITY_API_KEY TAVILY_API_KEY CEREBRAS_API_KEY XAI_API_KEY GROK_API_KEY TMUXAI_OPENROUTER_API_KEY KIMI_API_KEY ZAI_API_KEY PACKAGE_DS_REGISTRY_TOKEN CR_PAT
}

# Aliases
alias oldvim="vim"
alias vim="nvim"
alias vi="nvim"
alias python="python3"
alias deepagents="uv run deepagents"
alias kargox="docker compose -f docker-compose.dev.yml exec api"
alias grep='grep --color=auto'
alias ll='ls -lhF'
alias la='ls -lAhF'
alias md='mkdir -p'
alias ...='../..'
alias ....='../../..'

# FZF
# Colors are scoped in an anon function so they don't leak as globals
# (zsh's `colors` module also defines $fg/$bg and would clobber them).
() {
  local fg='#CBE0F0' bg='#011628' bg_highlight='#011628' purple='#C4A7E7'
  local blue='#2CF9ED' cyan='#00D0D0'
  export FZF_DEFAULT_OPTS="--color=fg:$fg,bg:$bg,hl:$purple,fg+:$fg,bg+:$bg_highlight,hl+:$purple,info:$blue,prompt:$cyan,pointer:$cyan,marker:$cyan,spinner:$cyan,header:$cyan"
}

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"
export FZF_COMPLETION_TRIGGER='**'

# Previews are inlined (not function calls) because fzf executes them via
# '$SHELL -c', which never reads .zshrc and can't see shell functions.
export FZF_CTRL_T_OPTS="--preview 'if [ -d {} ]; then eza --tree --color=always {} | head -n 200; else bat -n --color=always --line-range :500 {}; fi'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -n 200'"

# Interactive helper (for manual use; fzf previews no longer depend on it)
show_file_or_dir_preview() {
  if [ -d "$1" ]; then
    eza --tree --color=always "$1" | head -n 200
  else
    bat -n --color=always --line-range :500 "$1"
  fi
}

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
path=("$PYENV_ROOT/bin" $path)
if (( $+commands[pyenv] )); then
  eval "$(pyenv init --path)"
  eval "$(pyenv init - zsh)"
fi

# Antidote (plugin manager)
if [[ "$OS" == "macos" ]]; then
  if [[ -f "/opt/homebrew/opt/antidote/share/antidote/antidote.zsh" ]]; then
    source "/opt/homebrew/opt/antidote/share/antidote/antidote.zsh"
  elif (( $+commands[brew] )); then
    __ANTIDOTE_SCRIPT="$(brew --prefix)/opt/antidote/share/antidote/antidote.zsh"
    [[ -f "$__ANTIDOTE_SCRIPT" ]] && source "$__ANTIDOTE_SCRIPT"
    unset __ANTIDOTE_SCRIPT
  fi
else
  # Arch Linux
  if [[ -f "/usr/share/zsh-antidote/antidote.zsh" ]]; then
    source "/usr/share/zsh-antidote/antidote.zsh"
  elif [[ -f "$HOME/.antidote/antidote.zsh" ]]; then
    source "$HOME/.antidote/antidote.zsh"
  fi
fi

# Oh My Zsh compatibility: point $ZSH at antidote's ohmyzsh clone
export ZSH="$HOME/.oh-my-zsh"
if (( $+functions[antidote] )); then
  __ANTIDOTE_OMZ_PATH="$(antidote path ohmyzsh/ohmyzsh 2>/dev/null)"
  [[ -n "$__ANTIDOTE_OMZ_PATH" ]] && export ZSH="$__ANTIDOTE_OMZ_PATH"
  unset __ANTIDOTE_OMZ_PATH
fi

# Completion paths must be ready before compinit scans them.
export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/oh-my-zsh"
mkdir -p "$ZSH_CACHE_DIR/completions" 2>/dev/null || true
typeset -U fpath
fpath=("$ZSH_CACHE_DIR/completions" "$HOME/.grok/completions/zsh" $fpath)

# ez-compinit queues plugin compdef calls until the scan below.
if (( $+functions[antidote] )); then
  antidote load "${ZDOTDIR:-$HOME}/.zsh_plugins.txt"
fi
autoload -Uz compinit
compinit -i -d "${ZDOTDIR:-$HOME}/.zcompdump"

# Keep these styles after plugins, which may set their own defaults.
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' group-name ''

# Keep emacs keybindings authoritative (OMZ vi-mode plugin switches keymaps)
bindkey -e

# Tool init (guarded)
(( $+commands[fnm] ))      && eval "$(fnm env --use-on-cd --shell=zsh)"
(( $+commands[fzf] ))      && eval "$(fzf --zsh)"
(( $+commands[zoxide] ))   && eval "$(zoxide init zsh --cmd cd)"
(( $+commands[eza] ))      && alias ls="eza --icons=always"
(( $+commands[starship] )) && eval "$(starship init zsh)"

# macOS extras
if [[ "$OS" == "macos" ]]; then
  [[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"
  [[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"   # bun completions

  autoload -U +X bashcompinit && bashcompinit
  [[ -x "/opt/homebrew/bin/terraform" ]] && complete -o nospace -C /opt/homebrew/bin/terraform terraform

  [[ "$TERM_PROGRAM" == "kiro" ]] && (( $+commands[kiro] )) && . "$(kiro --locate-shell-integration-path zsh)"

  # Function (not alias) so the quoted path is parsed once, at definition time
  code() { '/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code' "$@" }
fi

# Custom functions
kimicc() {
  (( $+commands[op] )) || { echo 'op not found' >&2; return 1; }
  env ANTHROPIC_AUTH_TOKEN="$(op read 'op://Private/ENV_KIMI_API_KEY/password' 2>/dev/null)" ANTHROPIC_BASE_URL="https://api.moonshot.ai/anthropic" ANTHROPIC_MODEL= claude "$@"
}

qwen() {
  (( $+commands[op] )) || { echo 'op not found' >&2; return 1; }
  env OPENAI_API_KEY="$(op read 'op://Private/ENV_DASHSCOPE_COMPAT_API_KEY/password' 2>/dev/null)" \
      OPENAI_BASE_URL="https://dashscope-intl.aliyuncs.com/compatible-mode/v1" \
      OPENAI_MODEL="qwen3-coder-plus" \
      qwen "$@"
}

zai() {
  (( $+commands[op] )) || { echo 'op not found' >&2; return 1; }
  env ANTHROPIC_AUTH_TOKEN="$(op read 'op://Private/ENV_ZAI_API_KEY/password' 2>/dev/null)" ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic" ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-4.5-air" ANTHROPIC_DEFAULT_SONNET_MODEL="glm-4.6" ANTHROPIC_DEFAULT_OPUS_MODEL="glm-4.6" claude "$@"
}

# >>> forge initialize >>>
# Guarded: only load in interactive terminal sessions, not IDE/app-spawned shells
if (( $+commands[forge] )) && [[ -o interactive && ( "$TERM_PROGRAM" == "Apple_Terminal" || "$TERM_PROGRAM" == "iTerm.app" || "$TERM_PROGRAM" == "ghostty" || "$TERM_PROGRAM" == "WezTerm" || "$TERM_PROGRAM" == "tmux" || "$TERM_PROGRAM" == "cmux" ) ]]; then

  # Load forge shell plugin (commands, completions, keybindings) if not already loaded
  if [[ -z "$_FORGE_PLUGIN_LOADED" ]]; then
      eval "$(forge zsh plugin)"
  fi

  # Load forge shell theme (prompt with AI context) if not already loaded
  if [[ -z "$_FORGE_THEME_LOADED" ]]; then
      eval "$(forge zsh theme)"
  fi
fi
# <<< forge initialize <<<

# Optional shell integrations and machine-specific settings.
[[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/op/plugins.sh" ]] && source "${XDG_CONFIG_HOME:-$HOME/.config}/op/plugins.sh"
[[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/kaku/zsh/kaku.zsh" ]] && source "${XDG_CONFIG_HOME:-$HOME/.config}/kaku/zsh/kaku.zsh"
[[ -f "${ZDOTDIR:-$HOME}/.zshrc.local" ]] && source "${ZDOTDIR:-$HOME}/.zshrc.local"

# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"
