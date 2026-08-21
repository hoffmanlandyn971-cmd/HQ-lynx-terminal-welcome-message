#!/bin/bash

set -e

RAW_BASE="https://raw.githubusercontent.com/hoffmanlandyn971-cmd/HQ-lynx-terminal-welcome-message/refs/heads/main"

INSTALL_FILE="$HOME/welcome.sh"
CONFIG_DIR="$HOME/.config/welcome.sh"
CONFIG_FILE="$CONFIG_DIR/config"

echo "Installing Welcome.sh..."

mkdir -p "$CONFIG_DIR"

curl -fsSL "$RAW_BASE/welcome.sh" -o "$INSTALL_FILE"

chmod +x "$INSTALL_FILE"

echo "Welcome.sh installed successfully."

# Add Welcome.sh to Bash startup if it isn't already there
if ! grep -Fq "$HOME/welcome.sh" "$HOME/.bashrc" 2>/dev/null; then
    printf '\n# Welcome.sh\n[ -x "$HOME/welcome.sh" ] && "$HOME/welcome.sh"\n' >> "$HOME/.bashrc"
fi

echo "Startup configuration updated."
echo ""
echo "Run it now with:"
echo "  ~/welcome.sh"
echo ""
echo "Open a new terminal to load it automatically."
