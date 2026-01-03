#!/bin/bash

# --- Stop on first error ---
set -e

# --- Source our helper functions ---
source ./lib.sh

# ==============================================================================
#  create_link a single item from source to target
#
#  @param $1 The absolute path to the source file/directory.
#  @param $2 The absolute path to the target link.
# ==============================================================================
create_link() {
    local source_path="$1"
    local target_path="$2"

    # Ensure the target directory exists before trying to link
    mkdir -p "$(dirname "$target_path")"

    info "Processing link for: $(basename "$source_path")"

    # Handle cases where the target path already exists
    if [ -e "$target_path" ]; then
        # If it's not the link we want...
        if [ ! -L "$target_path" ] || [ "$(readlink "$target_path")" != "$source_path" ]; then
            backup_path="${target_path}~"
            info "  -> Backing up existing item to: $backup_path"
            # Overwrite any existing backup file
            rm -rf "$backup_path"
            # Rename with mv to create the backup
            mv "$target_path" "$backup_path"
        else
            info "  -> Correct link already exists, skipping."
            return 0 # Success, but nothing to do
        fi
    fi

    # Create the symbolic link. ln -v is verbose enough.
    info "  -> Creating new link..."
    ln -s -v "$source_path" "$target_path"
}


# ==============================================================================
#  Main Script Logic
# ==============================================================================
info "Starting to create symbolic links..."
echo ""

# --- Link .config files ---
info "--- Linking general .config files ---"
CONFIG_SOURCE_DIR="$HOME/.dotfiles/.config"
CONFIG_TARGET_DIR="$HOME/.config"
# Loop through all 1st level items in the source directory
find "$CONFIG_SOURCE_DIR" -mindepth 1 -maxdepth 1 | while read -r item; do
    # --- SPECIAL RULE: Exclude 'omarchy' from this generic loop ---
    if [ "$(basename "$item")" == "omarchy" ]; then
        info "Skipping 'omarchy' in generic loop (handled by a special rule below)."
        continue
    fi
    create_link "$item" "$CONFIG_TARGET_DIR/$(basename "$item")"
done
echo ""

# --- Special .config link rules ---
info "--- Applying special .config link rules ---"
# Rule for omarchy theme directory
info "-> Creating link for matcha theme..."
create_link \
    "$HOME/.dotfiles/.config/omarchy/themes/matcha" \
    "$HOME/.config/omarchy/themes/matcha"
echo ""


# --- Link .local files ---
info "--- Linking .local files ---"

# 1. Application .desktop files
info "-> Processing .desktop files..."
LOCAL_APPS_SOURCE_DIR="$HOME/.dotfiles/.local/share/applications"
LOCAL_APPS_TARGET_DIR="$HOME/.local/share/applications"
# Loop through all files (not directories) in the source
find "$LOCAL_APPS_SOURCE_DIR" -mindepth 1 -maxdepth 1 -type f | while read -r item; do
    create_link "$item" "$LOCAL_APPS_TARGET_DIR/$(basename "$item")"
done
echo ""

# 2. Application icon files
info "-> Processing application icon files..."
LOCAL_ICONS_SOURCE_DIR="$HOME/.dotfiles/.local/share/applications/icons"
LOCAL_ICONS_TARGET_DIR="$HOME/.local/share/applications/icons"
# Loop through all files (not directories) in the source
find "$LOCAL_ICONS_SOURCE_DIR" -mindepth 1 -maxdepth 1 -type f | while read -r item; do
    create_link "$item" "$LOCAL_ICONS_TARGET_DIR/$(basename "$item")"
done
echo ""

# 3. Specific style.css file for a theme
info "-> Processing specific theme files..."
CSS_SOURCE_FILE="$HOME/.dotfiles/.local/share/omarchy/default/walker/themes/omarchy-default/style.css"
CSS_TARGET_FILE="$HOME/.local/share/omarchy/default/walker/themes/omarchy-default/style.css"
create_link "$CSS_SOURCE_FILE" "$CSS_TARGET_FILE"
echo ""


info "Symbolic link creation script finished."
