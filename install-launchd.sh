#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
TEMPLATE_NAME="local.llama-swap.plist.template"
TEMPLATE_PATH="$PROJECT_DIR/$TEMPLATE_NAME"
PLIST_NAME="local.llama-swap.plist"
DEST_DIR="$HOME/Library/LaunchAgents"
DEST_PLIST="$DEST_DIR/$PLIST_NAME"
LABEL="local.llama-swap"
DOMAIN="gui/$(id -u)"
LLAMA_SWAP_BIN="$(command -v llama-swap || true)"
PATH_ENV="${PATH}:/usr/bin:/bin:/usr/sbin:/sbin"

mkdir -p "$DEST_DIR"

if [[ ! -f "$TEMPLATE_PATH" ]]; then
  echo "Missing template: $TEMPLATE_PATH" >&2
  exit 1
fi

if [[ -z "$LLAMA_SWAP_BIN" ]]; then
  echo "Could not find llama-swap in PATH. Install it first, e.g. via Homebrew." >&2
  exit 1
fi

python3 - <<'PY' "$TEMPLATE_PATH" "$DEST_PLIST" "$PROJECT_DIR" "$LLAMA_SWAP_BIN" "$PATH_ENV"
from pathlib import Path
import sys

template_path = Path(sys.argv[1])
dest_path = Path(sys.argv[2])
project_dir = sys.argv[3]
llama_swap_bin = sys.argv[4]
path_env = sys.argv[5]
content = template_path.read_text()
content = content.replace("__PROJECT_DIR__", project_dir)
content = content.replace("__LLAMA_SWAP_BIN__", llama_swap_bin)
content = content.replace("__PATH_ENV__", path_env)
dest_path.write_text(content)
PY

launchctl bootout "$DOMAIN" "$DEST_PLIST" >/dev/null 2>&1 || true
launchctl bootstrap "$DOMAIN" "$DEST_PLIST"
launchctl kickstart -k "$DOMAIN/$LABEL"

echo "Installed and started $LABEL"
echo "Project dir:  $PROJECT_DIR"
echo "Plist:        $DEST_PLIST"
echo "Health:       http://127.0.0.1:8080/health"
