#!/bin/bash

# ==============================================================================
#  Main Dotfiles Installation Script
#  This script orchestrates the entire setup process.
# ==============================================================================

# --- Stop on first error ---
set -e

# --- Set CWD to the script's directory ---
cd "$(dirname "$0")"

# --- Source our helper functions ---
source ./lib.sh

# --- Initial Setup & User Interaction ---

# 1. Cache sudo password
clear
echo "Install omarchy matcha theme"
echo ""
info "Caching sudo password for the duration of the script...\n"
sudo -v
# Keep sudo timestamp updated in the background
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done &
SUDO_LOOP_PID=$!
trap "kill $SUDO_LOOP_PID" EXIT ERR INT TERM

# 2. Check for failed tasks from a previous run
if [ -s "$FAILED_LOG_FILE" ]; then
    warning "Found a log of failed tasks from a previous run in $FAILED_LOG_FILE"
    if ask_confirmation "Do you want to attempt to re-run only the failed tasks?"; then
        info "--- Re-running Failed Tasks ---"
        mapfile -t failed_tasks < "$FAILED_LOG_FILE"
        > "$FAILED_LOG_FILE" # Clear the log file before re-running

        for task in "${failed_tasks[@]}"; do
            run_task "$task"
        done

        if [ -s "$FAILED_LOG_FILE" ]; then
            error "Some tasks failed again. Please review the output above and check the log: $FAILED_LOG_FILE"
        else
            info "All previously failed tasks succeeded."
        fi
        info "Re-run finished. Exiting."
        exit 0
    else
        warning "Proceeding with a full installation run."
    fi
fi

# 3. Full installation run
info "Starting a full installation run..."
mkdir -p "$LOG_DIR"
> "$FAILED_LOG_FILE" # Clear any old failures before a full run

NON_INTERACTIVE=false
read -p "Run full installation in non-interactive mode (skip all confirmations)? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    NON_INTERACTIVE=true
#    info "Non-interactive mode enabled for full run."
else
    info "Interactive mode enabled. You will be prompted before each step."
fi
echo ""

# --- Main Orchestration ---
#info "===== Starting Main Dotfiles Setup ====="
#echo ""

# STEP 1: OS Packages
if ask_confirmation "Do you want to install packages (pacman & yay)?"; then
    ./install_packages.sh
else
    warning "Skipping package installation."
fi
echo ""

# STEP 2: Hyprland Plugins
if ask_confirmation "Do you want to install Hyprland plugins?"; then
    ./install_hyprland_plugins.sh
#else
#    warning "Skipping Hyprland plugin installation."
fi

clear
#echo ""

# STEP 3: Google CLI
if ask_confirmation "Do you want to install the Google CLI?"; then
    ./install_google_cli.sh
else
    warning "Skipping Google CLI installation."
fi
echo ""

# STEP 4: Symbolic Links
if ask_confirmation "Do you want to create symbolic links?"; then
    ./create_links.sh
#else
#    warning "Skipping symbolic link creation."
fi
#echo ""


clear
# --- Final Status Check ---
if [ -s "$FAILED_LOG_FILE" ]; then
    warning "The setup script finished, but some NON-CRITICAL tasks failed."
    warning "Please check the log for details: $FAILED_LOG_FILE"
else
    info "===== Setup script finished successfully! ====="
    echo ""
    warning "Please see readme.md for any required manual steps (e.g., Firefox setup, enabling services)."
fi

exit 0
