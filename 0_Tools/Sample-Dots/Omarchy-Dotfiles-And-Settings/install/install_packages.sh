#!/bin/bash

# --- Stop on first error for critical parts ---
set -e

# --- Source our helper functions ---
source ./lib.sh

# --- Configuration ---
PACMAN_PKGLIST="./pkglist.txt"
AUR_PKGLIST="./aur_pkglist.txt"

# --- Main Logic for OS Package Installation ---
info "Starting OS package installation (pacman & yay)..."

# Check for package list files
if [ ! -f "$PACMAN_PKGLIST" ] || [ ! -f "$AUR_PKGLIST" ]; then
    error "Package lists (pkglist.txt, aur_pkglist.txt) not found."
fi

# --- CRITICAL SECTION ---
# Pacman packages are essential. If this fails, the whole script stops.
info "Installing packages from official repositories (pacman)..."
sudo pacman -S --needed --noconfirm - < "$PACMAN_PKGLIST"

# --- NON-CRITICAL SECTION ---
# AUR packages are considered non-critical.

info "--- DEBUGGING: Attempting YAY installation directly ---"
info "--------------------------------------------------------"
if ! command -v yay &> /dev/null; then
    warning "'yay' is not installed. Skipping AUR packages."
else
    set +e # Temporarily disable exit on error for yay command
    yay -S --needed --noconfirm - < "$AUR_PKGLIST"
    YAY_EXIT_CODE=$?
    set -e # Re-enable exit on error

    if [ $YAY_EXIT_CODE -eq 0 ]; then
        info "yay command completed successfully."
    else
        warning "yay command exited with code $YAY_EXIT_CODE. Please review the output above for details."
    fi
fi
info "--------------------------------------------------------"
info "--- END DEBUGGING YAY ---"


info "OS package installation script finished."