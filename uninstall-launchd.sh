#!/bin/bash
set -euo pipefail

PLIST_NAME="com.daniel.llama-swap.plist"
DEST_PLIST="$HOME/Library/LaunchAgents/$PLIST_NAME"
LABEL="com.daniel.llama-swap"
DOMAIN="gui/$(id -u)"

launchctl bootout "$DOMAIN" "$DEST_PLIST" >/dev/null 2>&1 || true
rm -f "$DEST_PLIST"

echo "Stopped and removed $LABEL"
