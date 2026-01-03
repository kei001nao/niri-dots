#!/bin/bash

# --- Stop on first error ---
set -e

# --- Source our helper functions ---
source ./lib.sh

# --- Main Logic for Hyprland Plugin Installation ---
info "Installing Hyprland plugins..."

if ! command -v hyprpm &> /dev/null; then
    warning "'hyprpm' command not found. Skipping Hyprland plugin installation."
    exit 0 # Exit gracefully, this is not a script error
fi

# --- Dependency Chain ---
# 1. Try to update.
if run_task "hyprpm update"; then
    # 2. If update succeeds, try to add the repo.
    if run_task "hyprpm add https://github.com/hyprwm/hyprland-plugins"; then
        # 3. If adding the repo succeeds, try to enable the plugins.
        info "Enabling plugins..."
        run_task "hyprpm enable hyprexpo"
        run_task "hyprpm enable hyprscrolling"
    fi
fi

info "Hyprland plugin script finished."
