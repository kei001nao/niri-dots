#!/bin/bash
#
# Firefox Customization Script
#
# This script sets up Firefox to use custom userChrome.css and userContent.css.
# It should be run AFTER Firefox has been started at least once to create a profile.
#

# --- Stop on first error ---
set -e

# --- Configuration ---
DOTFILES_DIR="$HOME/.dotfiles"

# --- Source our helper functions ---
source ./lib.sh

# --- Main Logic ---

info "Installing omarchy-theme-hook"
curl -fsSL https://imbypass.github.io/omarchy-theme-hook/install.sh | bash


info "Setting up Firefox userChrome.css..."

find_default_profile() {
    # Find the default profile path from profiles.ini
    awk -F= '
        /^\t\[Install\]/ { in_install=1 }
        in_install && /^Default=/ { print $2; exit }
    ' "$HOME/.mozilla/firefox/profiles.ini"
}

enable_userchrome() {
    # Enable the toolkit.legacyUserProfileCustomizations.stylesheets preference
    local default_profile_path="$1"
    if [ -z "$default_profile_path" ]; then
        warning "Default Firefox profile could not be determined. Skipping."
        return
    fi

    local prefs_file="$default_profile_path/prefs.js"
    local pref_name="toolkit.legacyUserProfileCustomizations.stylesheets"

    if [ ! -f "$prefs_file" ]; then
        # If prefs.js doesn't exist, create it before trying to modify it.
        touch "$prefs_file"
    fi

    # Check and set the preference
    if grep -qF "user_pref(\"$pref_name\"" "$prefs_file"; then
        if grep -qF "user_pref(\"$pref_name\", false)" "$prefs_file"; then
            sed -i.bak "s/user_pref(\"$pref_name\", false);/user_pref(\"$pref_name\", true);/" "$prefs_file"
            info "Enabled legacy user profile customizations in Firefox."
        else
            info "Legacy user profile customizations already enabled."
        fi
    else
        echo "user_pref(\"$pref_name\", true);" >> "$prefs_file"
        info "Enabled legacy user profile customizations in Firefox."
    fi
}

if [ -f "$HOME/.mozilla/firefox/profiles.ini" ]; then
    profile_rel_path=$(find_default_profile)
    if [ -n "$profile_rel_path" ]; then
        default_profile_abs_path="$HOME/.mozilla/firefox/$profile_rel_path"
        info "Found Firefox default profile: $default_profile_abs_path"
        
        # Copy userChrome files if they exist in dotfiles
        if [ -d "$DOTFILES_DIR/.mozilla" ]; then
            mkdir -p "$default_profile_abs_path/chrome"
            cp "$DOTFILES_DIR/.mozilla/firefox/release/chrome/userChrome.css" "$default_profile_abs_path/chrome/"
            cp "$DOTFILES_DIR/.mozilla/firefox/release/chrome/userContent.css" "$default_profile_abs_path/chrome/"
            info "Copied userChrome.css and userContent.css."
        else
            warning "No .mozilla directory in dotfiles. Skipping CSS copy."
        fi

        # Enable the necessary preference to load custom CSS
        enable_userchrome "$default_profile_abs_path"

    else
        warning "Could not find default profile in profiles.ini. Skipping Firefox setup."
    fi
else
    warning "Firefox profiles.ini not found. Please start Firefox at least once to create a profile."
    exit 1
fi

info "Firefox setup script finished successfully!"
exit 0
