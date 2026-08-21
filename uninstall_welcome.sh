#!/bin/bash

echo "Uninstalling Welcome.sh..."

rm -f "$HOME/welcome.sh"
rm -rf "$HOME/.config/welcome.sh"
rm -rf "$HOME/.cache/welcome.sh"

# Remove the Welcome.sh startup lines from .bashrc
if [ -f "$HOME/.bashrc" ]; then
    sed -i '/# Welcome\.sh/d' "$HOME/.bashrc"
    sed -i '/\[ -x "\$HOME\/welcome\.sh" \] && "\$HOME\/welcome\.sh"/d' "$HOME/.bashrc"
fi

echo ""
echo "✓ Welcome.sh has been completely removed."
echo "Open a new terminal to finish the cleanup."
