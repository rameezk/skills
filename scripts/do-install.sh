#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="$PWD"
INSTALLED_SKILLS=()

usage() {
  cat <<'EOF'
Usage: do-install.sh [options]

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

if [[ ! -t 0 ]] && { : </dev/tty; } 2>/dev/null; then
  exec </dev/tty
fi

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

  local overwrite_all=0
  for item in "${picked[@]}"; do
    local src="$dir/$item"
    local dst="$TARGET_DIR/.agents/skills/$item"

    mkdir -p "$(dirname "$dst")"

    if [[ -e "$dst" || -L "$dst" ]]; then
      if [[ "$overwrite_all" -eq 0 ]]; then
        read -r -p "'.agents/skills/$item' exists in target. Overwrite? [y/N/a=all] " overwrite
        if [[ "$overwrite" =~ ^[Aa]$ ]]; then
          overwrite_all=1
        elif [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
          echo "Skipped .agents/skills/$item"
          INSTALLED_SKILLS+=("$item")
          continue
        fi
      fi
      chmod -R u+w "$dst"
      rm -rf "$dst"
    fi

    cp -R "$src" "$dst"
    chmod -R u+w "$dst"
    echo "Copied .agents/skills/$item"
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

  local overwrite_all=0
  for item in "${INSTALLED_SKILLS[@]}"; do
    local dst="$link_root/$item"
    local target="../../.agents/skills/$item"

    if [[ -e "$dst" || -L "$dst" ]]; then
      if [[ "$overwrite_all" -eq 0 ]]; then
        read -r -p "'.claude/skills/$item' exists in target. Overwrite? [y/N/a=all] " overwrite
        if [[ "$overwrite" =~ ^[Aa]$ ]]; then
          overwrite_all=1
        elif [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
          echo "Skipped .claude/skills/$item"
          continue
        fi
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

choose_harness() {
  echo
  echo "Which coding harness are you using? (number, or Enter to skip):"
  echo "  [0] None"
  echo "  [1] Claude Code"
  echo "  [2] Pi"

  read -r -p "> " selection
  case "$selection" in
    "" | 0)
      return 0
      ;;
    1)
      link_skills_claude_code
      ;;
    2)
      confirm_skills_pi
      ;;
    *)
      echo "Skipping invalid selection: $selection"
      ;;
  esac
}

echo "Source: $SOURCE_DIR"
echo "Target: $TARGET_DIR"

choose_skills
choose_harness

echo
echo "Done."
