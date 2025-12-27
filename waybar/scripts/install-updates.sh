#!/bin/bash

# figlet "Updates" -f slant -w 44 -c  # optional, remove if not installed
echo "=== Updates ==="
echo ""

# Run Fedora updates
sudo dnf upgrade --refresh -y

notify-send "Updates complete"
echo "[INFO] OK"
sleep 2
