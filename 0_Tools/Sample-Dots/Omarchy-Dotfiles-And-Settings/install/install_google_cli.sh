#!/bin/bash

# --- Stop on first error ---
set -e

# --- Source our helper functions ---
source ./lib.sh

# --- Main Logic for Google CLI Installation ---
info "Installing Google-CLI..."

if ! command -v npm &> /dev/null; then
    warning "'npm' command not found. Skipping Google-CLI installation."
    exit 0
fi

run_task_with_spinner "sudo npm install -g @google/gemini-cli"

info "Google-CLI installation script finished."
