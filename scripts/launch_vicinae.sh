#!/bin/bash

# Configuration file for vicinae
CONFIG_FILE="$HOME/.config/vicinae/base_config.json"
TEMP_CONFIG_FILE="$HOME/.cache/vicinae_temp_config.json" # Temporary file to avoid corruption

# Define normal and AWWW-Switcher sizes
NORMAL_WIDTH=700
NORMAL_HEIGHT=580
AWWW_WIDTH=1600
AWWW_HEIGHT=840

# Determine target width and height based on argument
TARGET_WIDTH=$NORMAL_WIDTH
TARGET_HEIGHT=$NORMAL_HEIGHT

if [[ "$1" == "awww" ]]; then
    TARGET_WIDTH=$AWWW_WIDTH
    TARGET_HEIGHT=$AWWW_HEIGHT
    echo "Setting vicinae size for AWWW-Switcher mode: ${TARGET_WIDTH}x${TARGET_HEIGHT}"
else
    echo "Setting vicinae size for normal mode: ${TARGET_WIDTH}x${TARGET_HEIGHT}"
fi

# Update the base_config.json using jq
if [ -f "$CONFIG_FILE" ]; then
    jq --argjson width "$TARGET_WIDTH" --argjson height "$TARGET_HEIGHT" '.launcher_window.size.width = $width | .launcher_window.size.height = $height' "$CONFIG_FILE" > "$TEMP_CONFIG_FILE" && mv "$TEMP_CONFIG_FILE" "$CONFIG_FILE"
    if [ $? -eq 0 ]; then
        echo "Successfully updated $CONFIG_FILE"
    else
        echo "Error: Failed to update $CONFIG_FILE"
        exit 1
    fi
else
    echo "Error: Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# Launch vicinae
echo "Launching vicinae..."
if [[ "$1" == "awww" ]]; then
    vicinae vicinae://extensions/sovereign/awww-switcher/wpgrid
else
    vicinae toggle
fi
