#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="$PWD"

usage() {
  cat <<'EOF'
Usage: install-direct.sh [options]

Options:
  -h, --help         Show help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Target directory does not exist: $TARGET_DIR"
  exit 1
fi

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

  for item in "${picked[@]}"; do
    local src="$dir/$item"
    local dst="$TARGET_DIR/.agents/skills/$item"

    mkdir -p "$(dirname "$dst")"

    if [[ -e "$dst" || -L "$dst" ]]; then
      read -r -p "'.agents/skills/$item' exists in target. Overwrite? [y/N] " overwrite
      if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
        echo "Skipped .agents/skills/$item"
        continue
      fi
      rm -rf "$dst"
    fi

    cp -R "$src" "$dst"
    echo "Copied .agents/skills/$item"
  done
}

echo "Source: $SOURCE_DIR"
echo "Target: $TARGET_DIR"

choose_skills

echo
echo "Done."
