#!/bin/bash
set -euo pipefail

PLIST_NAME="local.llama-swap.plist"
DEST_PLIST="$HOME/Library/LaunchAgents/$PLIST_NAME"
LABEL="local.llama-swap"
DOMAIN="gui/$(id -u)"

launchctl bootout "$DOMAIN" "$DEST_PLIST" >/dev/null 2>&1 || true
rm -f "$DEST_PLIST"

echo "Stopped and removed $LABEL"
