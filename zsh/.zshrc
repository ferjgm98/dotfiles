# Cross-platform .zshrc (macOS + Arch Linux)

# Detect OS
case "$(uname -s)" in
  Darwin) OS="macos" ;;
  Linux)  OS="linux" ;;
  *)      OS="unknown" ;;
esac

# 1Password-backed env helpers (loads secrets only when you call secrets_on)
__OP_ENV_VAULT="Private"
secrets_on() {
  (( $+commands[op] )) || { echo 'op not found' >&2; return 1; }
  export OPENAI_API_KEY="$(op read "op://$__OP_ENV_VAULT/ENV_OPENAI_API_KEY/password" 2>/dev/null)"
  export ANTHROPIC_API_KEY="$(op read "op://$__OP_ENV_VAULT/ENV_ANTHROPIC_API_KEY/password" 2>/dev/null)"
  export OPENROUTER_API_KEY="$(op read "op://$__OP_ENV_VAULT/ENV_OPENROUTER_API_KEY/password" 2>/dev/null)"
  export GROQ_API_KEY="$(op read "op://$__OP_ENV_VAULT/ENV_GROQ_API_KEY/password" 2>/dev/null)"
  export GEMINI_API_KEY="$(op read "op://$__OP_ENV_VAULT/ENV_GEMINI_API_KEY/password" 2>/dev/null)"
  export MISTRAL_API_KEY="$(op read "op://$__OP_ENV_VAULT/ENV_MISTRAL_API_KEY/password" 2>/dev/null)"
  export PERPLEXITY_API_KEY="$(op read "op://$__OP_ENV_VAULT/ENV_PERPLEXITY_API_KEY/password" 2>/dev/null)"
  export TAVILY_API_KEY="$(op read "op://$__OP_ENV_VAULT/ENV_TAVILY_API_KEY/password" 2>/dev/null)"
  export CEREBRAS_API_KEY="$(op read "op://$__OP_ENV_VAULT/ENV_CEREBRAS_API_KEY/password" 2>/dev/null)"
  export XAI_API_KEY="$(op read "op://$__OP_ENV_VAULT/ENV_XAI_API_KEY/password" 2>/dev/null)"
  export GROK_API_KEY="$(op read "op://$__OP_ENV_VAULT/ENV_GROK_API_KEY/password" 2>/dev/null)"
  export TMUXAI_OPENROUTER_API_KEY="$(op read "op://$__OP_ENV_VAULT/ENV_TMUXAI_OPENROUTER_API_KEY/password" 2>/dev/null)"
  export KIMI_API_KEY="$(op read "op://$__OP_ENV_VAULT/ENV_KIMI_API_KEY/password" 2>/dev/null)"
  export ZAI_API_KEY="$(op read "op://$__OP_ENV_VAULT/ENV_ZAI_API_KEY/password" 2>/dev/null)"
  export PACKAGE_DS_REGISTRY_TOKEN="$(op read "op://$__OP_ENV_VAULT/ENV_PACKAGE_DS_REGISTRY_TOKEN/password" 2>/dev/null)"
  export CR_PAT="$(op read "op://$__OP_ENV_VAULT/ENV_CR_PAT/password" 2>/dev/null)"
}
secrets_off() {
  unset OPENAI_API_KEY ANTHROPIC_API_KEY OPENROUTER_API_KEY GROQ_API_KEY GEMINI_API_KEY MISTRAL_API_KEY PERPLEXITY_API_KEY TAVILY_API_KEY CEREBRAS_API_KEY XAI_API_KEY GROK_API_KEY TMUXAI_OPENROUTER_API_KEY KIMI_API_KEY ZAI_API_KEY PACKAGE_DS_REGISTRY_TOKEN CR_PAT
}

# Fast path for lightweight shells (Cursor Agent or ClaudeCode)
if [[ -n "$CURSOR_AGENT" || -n "$CLAUDECODE" || "$TERM_PROGRAM" == "cursor" ]]; then
  export PROMPT='%n@%m:%~ %# '
  export RPROMPT=''
  export DISABLE_AUTO_TITLE="true"
  export OMZ_DISABLE_AUTO_UPDATE="true"
  export ZSH_DISABLE_COMPFIX="true"
  
  # Essential PATH additions only
  if [[ "$OS" == "macos" ]]; then
    export PNPM_HOME="$HOME/Library/pnpm"
    if [[ -d "/opt/homebrew/bin" ]]; then
      export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
    else
      export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
    fi
  else
    export PNPM_HOME="$HOME/.local/share/pnpm"
  fi
  export PATH="$PNPM_HOME:$HOME/.local/bin:$PATH"
  
  (( $+commands[fnm] )) && eval "$(fnm env --use-on-cd --shell=zsh)"
  return
fi

# PATH (deduped, single place)
typeset -U path PATH

export BUN_INSTALL="$HOME/.bun"

# OS-specific PATH setup
if [[ "$OS" == "macos" ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
  path=(
    /opt/homebrew/bin(N-/)
    /opt/homebrew/sbin(N-/)
    /usr/local/bin(N-/)
    /usr/local/sbin(N-/)
    /opt/homebrew/opt/php@8.0/bin(N-/)
    /opt/homebrew/opt/php@8.0/sbin(N-/)
    /opt/homebrew/opt/postgresql@15/bin(N-/)
    /opt/homebrew/opt/openjdk@17/bin(N-/)
    "$HOME/.local/bin"
    "$PNPM_HOME"
    "$BUN_INSTALL/bin"
    "$HOME/.lmstudio/bin"
    "$HOME/.opencode/bin"
    "$HOME/.antigravity/antigravity/bin"
    $path
  )
  if [[ -d "/opt/homebrew/opt/openjdk@17/include" ]]; then
    export CPPFLAGS="-I/opt/homebrew/opt/openjdk@17/include"
  fi
else
  # Linux (Arch)
  export PNPM_HOME="$HOME/.local/share/pnpm"
  path=(
    "$HOME/.local/bin"
    "$PNPM_HOME"
    "$BUN_INSTALL/bin"
    "$HOME/.lmstudio/bin"
    "$HOME/.opencode/bin"
    /usr/local/bin
    $path
  )
fi

# Editor
export EDITOR="nvim"

# Aliases
alias oldvim="vim"
alias vim="nvim"
alias vi="nvim"
alias python="python3"
alias deepagents="uv run deepagents"
alias kargox="docker compose -f docker-compose.dev.yml exec api"

# FZF Colors
fg='#CBE0F0'
bg='#011628'
bg_highlight='#011628'
purple='#C4A7E7'
blue='#2CF9ED'
cyan='#00D0D0'

export FZF_DEFAULT_OPTS="--color=fg:$fg,bg:$bg,hl:$purple,fg+:$fg,bg+:$bg_highlight,hl+:$purple,info:$blue,prompt:$cyan,pointer:$cyan,marker:$cyan,spinner:$cyan,header:$cyan"

# FZF Commands
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

show_file_or_dir_preview() {
  if [ -d "$1" ]; then
    eza --tree --color=always "$1" | head -n 200
  else
    bat -n --color=always --line-range :500 "$1"
  fi
}

export FZF_COMPLETION_TRIGGER='**'
export FZF_CTRL_T_OPTS="--preview 'show_file_or_dir_preview {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -n 200'"

# PYENV
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init - zsh)"
fi

# Antidote (cross-platform)
if [[ "$OS" == "macos" ]]; then
  if [[ -f "/opt/homebrew/opt/antidote/share/antidote/antidote.zsh" ]]; then
    source "/opt/homebrew/opt/antidote/share/antidote/antidote.zsh"
  elif (( $+commands[brew] )); then
    source "$(brew --prefix)/opt/antidote/share/antidote/antidote.zsh"
  fi
else
  # Arch Linux
  if [[ -f "/usr/share/zsh-antidote/antidote.zsh" ]]; then
    source "/usr/share/zsh-antidote/antidote.zsh"
  elif [[ -f "$HOME/.antidote/antidote.zsh" ]]; then
    source "$HOME/.antidote/antidote.zsh"
  fi
fi

# OMZ compatibility
export ZSH="$HOME/.oh-my-zsh"
if (( $+commands[antidote] )); then
  __ANTIDOTE_OMZ_PATH="$(antidote path ohmyzsh/ohmyzsh 2>/dev/null)"
  [[ -n "$__ANTIDOTE_OMZ_PATH" ]] && export ZSH="$__ANTIDOTE_OMZ_PATH"
  unset __ANTIDOTE_OMZ_PATH
fi

export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/oh-my-zsh"
mkdir -p "$ZSH_CACHE_DIR/completions" 2>/dev/null || true

# Load plugins
if (( $+commands[antidote] )); then
  antidote load "${ZDOTDIR:-$HOME}/.zsh_plugins.txt"
fi

# Completion system (after plugins add completions)
autoload -Uz compinit
compinit -i -d "${ZDOTDIR:-$HOME}/.zcompdump"

# Tool init (guarded)
(( $+commands[fnm] ))    && eval "$(fnm env --use-on-cd --shell=zsh)"
(( $+commands[fzf] ))    && eval "$(fzf --zsh)"
(( $+commands[zoxide] )) && eval "$(zoxide init zsh --cmd cd)"
(( $+commands[eza] ))    && alias ls="eza --icons=always"
(( $+commands[starship] )) && eval "$(starship init zsh)"

# OS-specific extras
if [[ "$OS" == "macos" ]]; then
  [[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"
  [[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"
  
  autoload -U +X bashcompinit && bashcompinit
  [[ -x "/opt/homebrew/bin/terraform" ]] && complete -o nospace -C /opt/homebrew/bin/terraform terraform
  
  [[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"
  
  # Kiro CLI blocks
  [[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"
  [[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"
  
  alias code='/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code'
fi

# Custom functions (work on both)
kimicc() {
  (( $+commands[op] )) || { echo 'op not found' >&2; return 1; }
  env ANTHROPIC_AUTH_TOKEN="$(op read 'op://Private/ENV_KIMI_API_KEY/password' 2>/dev/null)" ANTHROPIC_BASE_URL="https://api.moonshot.ai/anthropic" ANTHROPIC_MODEL= claude "$@"
}

qwen() {
  (( $+commands[op] )) || { echo 'op not found' >&2; return 1; }
  env OPENAI_API_KEY="$(op read 'op://Private/ENV_DASHSCOPE_COMPAT_API_KEY/password' 2>/dev/null)" \
      OPENAI_BASE_URL="https://dashscope-intl.aliyuncs.com/compatible-mode/v1" \
      OPENAI_MODEL="qwen3-coder-plus" \
      command qwen "$@"
}

zai() {
  (( $+commands[op] )) || { echo 'op not found' >&2; return 1; }
  env ANTHROPIC_AUTH_TOKEN="$(op read 'op://Private/ENV_ZAI_API_KEY/password' 2>/dev/null)" ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic" ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-4.5-air" ANTHROPIC_DEFAULT_SONNET_MODEL="glm-4.6" ANTHROPIC_DEFAULT_OPUS_MODEL="glm-4.6" claude "$@"
}

export PACKAGE_PROJECT_ID=70576898
