#!/bin/bash
set -euo pipefail

PROJECT_DIR="/Users/daniel.kirsch/code/llamaswap"
PLIST_NAME="com.daniel.llama-swap.plist"
SRC_PLIST="$PROJECT_DIR/$PLIST_NAME"
DEST_DIR="$HOME/Library/LaunchAgents"
DEST_PLIST="$DEST_DIR/$PLIST_NAME"
LABEL="com.daniel.llama-swap"
DOMAIN="gui/$(id -u)"

mkdir -p "$DEST_DIR"

launchctl bootout "$DOMAIN" "$DEST_PLIST" >/dev/null 2>&1 || true
rm -f "$DEST_PLIST"
ln -s "$SRC_PLIST" "$DEST_PLIST"

launchctl bootstrap "$DOMAIN" "$DEST_PLIST"
launchctl kickstart -k "$DOMAIN/$LABEL"

echo "Installed and started $LABEL"
echo "Plist source: $SRC_PLIST"
echo "Plist link:   $DEST_PLIST"
echo "Health:       http://127.0.0.1:8080/health"
