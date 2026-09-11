#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/rameezk/skills.git"
PASSTHROUGH_ARGS=("$@")

usage() {
  cat <<'EOF'
Usage: install.sh
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -x "$SCRIPT_DIR/scripts/do-install.sh" ]]; then
  exec "$SCRIPT_DIR/scripts/do-install.sh" "${PASSTHROUGH_ARGS[@]}"
fi

if ! command -v git >/dev/null 2>&1; then
  echo "git is required for curl/piped install mode."
  exit 1
fi

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

git clone --depth 1 "$REPO_URL" "$TMP_DIR/repo" >/dev/null 2>&1
exec "$TMP_DIR/repo/scripts/do-install.sh" "${PASSTHROUGH_ARGS[@]}"
