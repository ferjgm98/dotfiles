#!/bin/bash
# Git status for tmux status bar with gruvbox colors and icons

cd "$1" 2>/dev/null || exit 0

# Check if inside a git repo
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
[ -z "$branch" ] && exit 0

# Count file statuses from porcelain output
staged=0
modified=0
deleted=0

while IFS= read -r line; do
  index="${line:0:1}"
  worktree="${line:1:1}"

  # Staged (index) changes
  case "$index" in
    A|M|R|C) ((staged++)) ;;
    D) ((deleted++)) ;;
  esac

  # Worktree (unstaged) changes
  case "$worktree" in
    M) ((modified++)) ;;
    D) ((deleted++)) ;;
    \?) ((modified++)) ;;  # untracked files count as modified
  esac
done < <(git status --porcelain 2>/dev/null)

# Gruvbox colors
green="#b8bb26"
yellow="#fabd2f"
red="#fb4934"
aqua="#8ec07c"

# Build output
output="#[fg=${aqua}] ${branch}"

[ "$staged" -gt 0 ] && output="${output} #[fg=${green}]+${staged}"
[ "$modified" -gt 0 ] && output="${output} #[fg=${yellow}]~${modified}"
[ "$deleted" -gt 0 ] && output="${output} #[fg=${red}]-${deleted}"

echo "$output"
