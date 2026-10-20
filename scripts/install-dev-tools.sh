#!/usr/bin/env bash
set -Eeuo pipefail

MODE=install
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) MODE=plan ;;
    --check) MODE=check ;;
    -h|--help)
      echo "Usage: install-dev-tools.sh [--dry-run|--check]"
      echo "Install missing tools from update_dependencies.sh. Requires fnm and uv."
      exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 1 ;;
  esac
  shift
done

export PATH="$HOME/.local/bin:$HOME/.bun/bin:$HOME/.amp/bin:$HOME/.kimi-code/bin:$HOME/.opencode/bin:$HOME/.grok/bin:$PATH"
if [[ "$(uname -s)" == Darwin ]]; then
  export PATH="$PATH:/Applications/Kiro CLI.app/Contents/MacOS"
fi
TOOLS=(node npm corepack pnpm bun uv claude forge copilot cline mastracode codex pi amp cursor-agent devin droid kiro-cli kimi vibe opencode grok agy kirocrew fx muse)

check_tools() {
  local missing=0 tool
  for tool in "${TOOLS[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
      printf '[OK] %s\n' "$tool"
    else
      printf '[MISSING] %s\n' "$tool"
      missing=1
    fi
  done
  return "$missing"
}

if [[ "$MODE" == check ]]; then
  check_tools
  exit
fi

trap 'echo "[ERROR] Tool installation stopped. Fix the error above and rerun; installed tools are kept." >&2' ERR

install_script() (
  local tool="$1" shell="$2" url="$3"
  shift 3
  if command -v "$tool" >/dev/null 2>&1; then
    printf '[OK] Already installed: %s\n' "$tool"
    exit 0
  fi
  printf '[INSTALL] %s: %s\n' "$tool" "$url"
  [[ "$MODE" == plan ]] && exit 0
  local temp
  temp="$(mktemp -d)"
  trap 'rm -rf "$temp"' EXIT
  curl -fsSL --retry 2 --connect-timeout 20 "$url" -o "$temp/install.sh"
  # Keep vendor shell setup away from the tracked .zshrc.
  # Non-terminal output also keeps Pi from launching its first-run UI.
  if [[ "$tool" == grok || "$tool" == agy ]]; then
    SHELL=/bin/sh "$shell" "$temp/install.sh" "$@" </dev/null | cat
  else
    "$shell" "$temp/install.sh" "$@" </dev/null | cat
  fi
  command -v "$tool" >/dev/null 2>&1 || {
    printf '[ERROR] Installer finished but %s is not on PATH. Check its output before rerunning.\n' "$tool" >&2
    exit 1
  }
)

install_forge() (
  if command -v forge >/dev/null 2>&1; then
    echo '[OK] Already installed: forge'
    exit 0
  fi
  local target arch temp
  case "$(uname -s)" in
    Darwin) target=apple-darwin ;;
    Linux) target=unknown-linux-gnu ;;
    *) echo 'Forge install supports macOS and Linux.' >&2; exit 1 ;;
  esac
  case "$(uname -m)" in
    arm64|aarch64) arch=aarch64 ;;
    x86_64) arch=x86_64 ;;
    *) echo 'Unsupported Forge architecture.' >&2; exit 1 ;;
  esac
  # forgecode.dev/cli returns 404; use the project's published release binary.
  local url="https://github.com/tailcallhq/forgecode/releases/latest/download/forge-$arch-$target"
  printf '[INSTALL] forge: %s\n' "$url"
  [[ "$MODE" == plan ]] && exit 0
  temp="$(mktemp -d)"
  trap 'rm -rf "$temp"' EXIT
  curl -fsSL --retry 2 --connect-timeout 20 "$url" -o "$temp/forge"
  install -m 755 "$temp/forge" "$HOME/.local/bin/forge"
)

install_npm_tool() {
  local tool="$1" package="$2"
  if [[ "$MODE" == plan ]]; then
    printf '[PLAN] Ensure %s is installed in the fnm Node prefix (%s).\n' "$tool" "$package"
    return
  fi
  if [[ -x "$NODE_BIN/$tool" ]]; then
    printf '[OK] Already installed in Node prefix: %s\n' "$tool"
    return
  fi
  printf '[INSTALL] %s: npm package %s\n' "$tool" "$package"
  "$NODE_BIN/npm" install -g --prefix "$NODE_PREFIX" "$package"
}

if [[ "$MODE" == plan ]]; then
  echo '[PLAN] Use the fnm default Node; install Node LTS if no default exists.'
  echo '[PLAN] Install Corepack and activate pnpm if missing.'
else
  for tool in fnm uv curl; do
    command -v "$tool" >/dev/null 2>&1 || {
      printf '[ERROR] %s is required. Run the platform bootstrap first.\n' "$tool" >&2
      exit 1
    }
  done
  mkdir -p "$HOME/.local/bin"
  if ! NODE_EXE="$(fnm exec --using default node -p 'process.execPath' 2>/dev/null)"; then
    fnm install --lts
    fnm default lts-latest
    NODE_EXE="$(fnm exec --using default node -p 'process.execPath')"
  fi
  NODE_BIN="$(dirname "$NODE_EXE")"
  NODE_PREFIX="$(dirname "$NODE_BIN")"
  # Hermes or another shim can shadow fnm's node and send global packages elsewhere.
  export PATH="$NODE_BIN:$PATH"
  "$NODE_EXE" -e 'const [major, minor] = process.versions.node.split(".").map(Number); if (major < 22 || (major === 22 && minor < 19)) { console.error("Node 22.19+ required. Run fnm install --lts && fnm default lts-latest, then retry."); process.exit(1); }'
  install_npm_tool corepack corepack
  if [[ ! -x "$NODE_BIN/pnpm" ]]; then
    COREPACK_ENABLE_DOWNLOAD_PROMPT=0 "$NODE_BIN/corepack" install -g pnpm@latest
    "$NODE_BIN/corepack" enable --install-directory "$NODE_BIN" pnpm
  fi
fi

install_script bun bash https://bun.sh/install
install_npm_tool copilot @github/copilot
install_npm_tool cline cline
install_npm_tool mastracode mastracode
if command -v vibe >/dev/null 2>&1; then
  echo '[OK] Already installed: vibe'
elif [[ "$MODE" == plan ]]; then
  echo '[INSTALL] vibe: uv tool install --python 3.12 mistral-vibe'
else
  uv tool install --python 3.12 mistral-vibe
fi

install_script claude bash https://claude.ai/install.sh
install_forge
install_script codex sh https://chatgpt.com/codex/install.sh
install_script pi sh https://pi.dev/install.sh
install_script amp bash https://ampcode.com/install.sh
install_script cursor-agent bash https://cursor.com/install
install_script devin bash https://cli.devin.ai/install.sh
install_script droid sh https://app.factory.ai/cli
install_script kiro-cli bash https://cli.kiro.dev/install
export KIMI_NO_MODIFY_PATH=1 MUSE_NO_MODIFY_PATH=1
install_script kimi bash https://code.kimi.com/kimi-code/install.sh
install_script opencode bash https://opencode.ai/install --no-modify-path
install_script grok bash https://x.ai/cli/install.sh
install_script agy bash https://antigravity.google/cli/install.sh
install_script kirocrew sh https://download.crew.kiro.dev/cli.sh
install_script fx bash https://fx.sh/setup.sh
install_script muse bash https://dev.meta.ai/install.sh

if [[ "$MODE" == install ]]; then
  check_tools
  echo '[OK] Developer tools installed. Open a new terminal and sign in to each tool you use.'
  echo 'Kiro Crew also needs: kiro-cli login, then kirocrew setup.'
fi
