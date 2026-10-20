#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="$PWD"
LOCK_FILE="$TARGET_DIR/.agents/skills.lock"
WORKFLOW_FILE="$TARGET_DIR/.github/workflows/sync-skills.yml"
SOURCE_URL="https://github.com/rameezk/skills.git"
SYNC=0
OVERWRITE_ALL=0
HARNESS=""
INSTALLED_SKILLS=()
LOCKED_SKILLS=()
LOCKED_HARNESS=""
LOCKED_SOURCE=""

usage() {
  cat <<'EOF'
Usage: do-install.sh [options]

Options:
  --sync             Re-copy the skills listed in .agents/skills.lock without prompting
  -h, --help         Show help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sync)
      SYNC=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ "$SYNC" -eq 0 && ! -t 0 ]] && { : </dev/tty; } 2>/dev/null; then
  exec </dev/tty
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_REV="${SKILLS_REV:-$(git -C "$SOURCE_DIR" rev-parse HEAD 2>/dev/null || echo unknown)}"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Target directory does not exist: $TARGET_DIR"
  exit 1
fi

read_lock() {
  if [[ ! -f "$LOCK_FILE" ]]; then
    return 0
  fi

  local key value
  while read -r key value; do
    case "$key" in
      skill) LOCKED_SKILLS+=("$value") ;;
      harness) LOCKED_HARNESS="$value" ;;
      source) LOCKED_SOURCE="$value" ;;
    esac
  done < "$LOCK_FILE"
}

write_lock() {
  local skills=("$@")

  if [[ ${#skills[@]} -eq 0 ]]; then
    rm -f "$LOCK_FILE"
    return 0
  fi

  mkdir -p "$(dirname "$LOCK_FILE")"
  {
    echo "source ${LOCKED_SOURCE:-$SOURCE_URL}"
    echo "rev $SOURCE_REV"
    echo "harness ${HARNESS:-none}"
    printf '%s\n' "${skills[@]}" | sort -u | sed 's/^/skill /'
  } > "$LOCK_FILE"
  echo "Wrote .agents/skills.lock at $SOURCE_REV"
}

may_overwrite() {
  local path="$1"
  local answer

  if [[ "$SYNC" -eq 1 || "$OVERWRITE_ALL" -eq 1 ]]; then
    return 0
  fi

  read -r -p "'$path' exists in target. Overwrite? [y/N/a=all] " answer
  if [[ "$answer" =~ ^[Aa]$ ]]; then
    OVERWRITE_ALL=1
    return 0
  fi
  [[ "$answer" =~ ^[Yy]$ ]]
}

copy_skill() {
  local item="$1"
  local src="$SOURCE_DIR/skills/$item"
  local dst="$TARGET_DIR/.agents/skills/$item"

  mkdir -p "$(dirname "$dst")"

  if [[ -e "$dst" || -L "$dst" ]]; then
    if ! may_overwrite ".agents/skills/$item"; then
      echo "Skipped .agents/skills/$item"
      return 0
    fi
    chmod -R u+w "$dst"
    rm -rf "$dst"
  fi

  cp -R "$src" "$dst"
  chmod -R u+w "$dst"
  echo "Copied .agents/skills/$item"
}

remove_skill() {
  local item="$1"
  local dst="$TARGET_DIR/.agents/skills/$item"
  local link="$TARGET_DIR/.claude/skills/$item"

  if [[ -e "$dst" ]]; then
    chmod -R u+w "$dst"
    rm -rf "$dst"
  fi
  if [[ -L "$link" ]]; then
    rm -f "$link"
  fi
  echo "Removed .agents/skills/$item because it no longer exists in the source"
}

choose_skills() {
  local dir="$SOURCE_DIR/skills"

  if [[ ! -d "$dir" ]]; then
    echo "No skills directory found at: $dir"
    return 0
  fi

  mapfile -t items < <(find "$dir" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)
  if [[ ${#items[@]} -eq 0 ]]; then
    echo "No skills found in: $dir"
    return 0
  fi

  echo
  echo "Select skills to install (comma-separated numbers, 'all', or Enter to skip):"
  local i=1
  for item in "${items[@]}"; do
    echo "  [$i] $item"
    ((i++))
  done

  read -r -p "> " selection
  if [[ -z "$selection" ]]; then
    return 0
  fi

  local picked=()
  if [[ "$selection" == "all" ]]; then
    picked=("${items[@]}")
  else
    IFS=',' read -r -a indices <<< "$selection"
    for idx_raw in "${indices[@]}"; do
      idx="${idx_raw//[[:space:]]/}"
      if [[ "$idx" =~ ^[0-9]+$ ]] && (( idx >= 1 && idx <= ${#items[@]} )); then
        picked+=("${items[$((idx-1))]}")
      else
        echo "Skipping invalid selection: $idx_raw"
      fi
    done
  fi

  OVERWRITE_ALL=0
  for item in "${picked[@]}"; do
    copy_skill "$item"
    INSTALLED_SKILLS+=("$item")
  done
}

link_skills_claude_code() {
  local link_root="$TARGET_DIR/.claude/skills"

  if [[ ${#INSTALLED_SKILLS[@]} -eq 0 ]]; then
    echo "No installed skills to link into .claude/skills."
    return 0
  fi

  mkdir -p "$link_root"

  OVERWRITE_ALL=0
  for item in "${INSTALLED_SKILLS[@]}"; do
    local dst="$link_root/$item"
    local target="../../.agents/skills/$item"

    if [[ -L "$dst" && "$(readlink "$dst")" == "$target" ]]; then
      continue
    fi

    if [[ -e "$dst" || -L "$dst" ]]; then
      if ! may_overwrite ".claude/skills/$item"; then
        echo "Skipped .claude/skills/$item"
        continue
      fi
      rm -rf "$dst"
    fi

    ln -s "$target" "$dst"
    echo "Linked .claude/skills/$item -> .agents/skills/$item"
  done
}

confirm_skills_pi() {
  if [[ ${#INSTALLED_SKILLS[@]} -eq 0 ]]; then
    echo "No installed skills for pi to discover."
    return 0
  fi

  echo "Skills are installed in .agents/skills, which pi discovers automatically from the git root down. Nothing to link."
}

apply_harness() {
  case "$HARNESS" in
    claude-code) link_skills_claude_code ;;
    pi) confirm_skills_pi ;;
  esac
}

choose_harness() {
  echo
  echo "Which coding harness are you using? (number, or Enter to skip):"
  echo "  [0] None"
  echo "  [1] Claude Code"
  echo "  [2] Pi"

  read -r -p "> " selection
  case "$selection" in
    "")
      HARNESS="$LOCKED_HARNESS"
      return 0
      ;;
    0)
      HARNESS="none"
      ;;
    1)
      HARNESS="claude-code"
      ;;
    2)
      HARNESS="pi"
      ;;
    *)
      echo "Skipping invalid selection: $selection"
      HARNESS="$LOCKED_HARNESS"
      return 0
      ;;
  esac
  apply_harness
}

offer_sync_workflow() {
  if [[ -e "$WORKFLOW_FILE" || ! -f "$LOCK_FILE" ]]; then
    return 0
  fi

  echo
  read -r -p "Add a weekly workflow that opens a pull request when these skills change upstream? [Y/n] " answer
  if [[ "$answer" =~ ^[Nn]$ ]]; then
    return 0
  fi

  mkdir -p "$(dirname "$WORKFLOW_FILE")"
  cat > "$WORKFLOW_FILE" <<'EOF'
name: Sync skills

on:
  schedule:
    - cron: "0 6 * * 1"
  workflow_dispatch:
    inputs:
      ref:
        description: Branch, tag, or commit of the skills repo to sync to
        default: main

permissions:
  contents: write
  pull-requests: write

jobs:
  sync:
    uses: rameezk/skills/.github/workflows/sync-skills.yml@main
    with:
      ref: ${{ inputs.ref || 'main' }}
EOF
  echo "Wrote .github/workflows/sync-skills.yml"
}

sync_skills() {
  if [[ ! -f "$LOCK_FILE" ]]; then
    echo "No .agents/skills.lock in $TARGET_DIR. Run the installer without --sync first."
    exit 1
  fi

  for item in "${LOCKED_SKILLS[@]}"; do
    if [[ -d "$SOURCE_DIR/skills/$item" ]]; then
      copy_skill "$item"
      INSTALLED_SKILLS+=("$item")
    else
      remove_skill "$item"
    fi
  done

  HARNESS="$LOCKED_HARNESS"
  apply_harness
  write_lock "${INSTALLED_SKILLS[@]}"
}

echo "Source: $SOURCE_DIR ($SOURCE_REV)"
echo "Target: $TARGET_DIR"

read_lock

if [[ "$SYNC" -eq 1 ]]; then
  sync_skills
else
  choose_skills
  choose_harness
  write_lock "${LOCKED_SKILLS[@]}" "${INSTALLED_SKILLS[@]}"
  offer_sync_workflow
fi

echo
echo "Done."
