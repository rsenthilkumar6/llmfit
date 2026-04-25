#!/bin/bash
# sync_plist.sh - Stop, copy, unload and load plist files for llmfit server

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAUNCHAGENTS="$HOME/Library/LaunchAgents"

echo "=== Stopping services ==="
launchctl stop ai.llmfit.server 2>/dev/null || echo "  (no server to stop)"
launchctl stop ai.llmfit.trigger 2>/dev/null || echo "  (no trigger to stop)"

sleep 1

echo "=== Copying plists to LaunchAgents ==="
cp "$SCRIPT_DIR/ai.llmfit.server.plist" "$LAUNCHAGENTS/"
cp "$SCRIPT_DIR/ai.llmfit.trigger.plist" "$LAUNCHAGENTS/"
echo " Copied to $LAUNCHAGENTS/"

echo "=== Unloading old plists ==="
launchctl unload "$LAUNCHAGENTS/ai.llmfit.server.plist" 2>/dev/null || echo "  (no server plist to unload)"
launchctl unload "$LAUNCHAGENTS/ai.llmfit.trigger.plist" 2>/dev/null || echo "  (no trigger plist to unload)"

echo "=== Loading new plists ==="
launchctl load "$LAUNCHAGENTS/ai.llmfit.trigger.plist"
launchctl load "$LAUNCHAGENTS/ai.llmfit.server.plist"

echo "=== Services status ==="
launchctl list | grep llmfit

echo "Done!"