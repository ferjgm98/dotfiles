#!/usr/bin/env bash

backup_and_link() {
  local src="$1" dest="$2" backup suffix=0

  if [[ ! -e "$src" ]]; then
    printf '[WARN] Missing source: %s\n' "$src" >&2
    return 1
  fi
  if [[ -L "$dest" && "$src" -ef "$dest" ]]; then
    printf '[OK] Already linked: %s\n' "$dest"
    return 0
  fi
  printf '[LINK] %s -> %s\n' "$dest" "$src"
  [[ "${DRY_RUN:-0}" -eq 1 ]] && return 0

  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" || -L "$dest" ]]; then
    backup="$dest.bak.$(date +%Y%m%d%H%M%S)"
    while [[ -e "$backup" || -L "$backup" ]]; do
      suffix=$((suffix + 1))
      backup="$dest.bak.$(date +%Y%m%d%H%M%S).$suffix"
    done
    mv "$dest" "$backup"
    printf '[BACKUP] %s\n' "$backup"
  fi
  ln -s "$src" "$dest"
}
