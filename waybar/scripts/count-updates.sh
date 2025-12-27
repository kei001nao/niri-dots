#!/bin/bash
# Count available DNF updates
updates=$(dnf check-update --quiet 2>/dev/null | grep -vE "^$|^Last metadata|Obsoleting Packages" | wc -l)
updates=${updates:-0}

if [ "$updates" -gt 0 ]; then
    # Show update icon + number in Waybar
    printf '{"text": " %s", "tooltip": "%s updates available"}' "$updates" "$updates"
else
    # Hide module when no updates
    echo ""
fi