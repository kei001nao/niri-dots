#!/bin/bash

WALL_PATH=$(awww query | grep -oP '/[^ ]+\.(png|jpg|jpeg|webp)' | head -n 1)

# 2. hyprlock.conf の 9行目を新しいパスで置換
# 行全体を "$wallpaper = [取得したパス]" に書き換えます
if [ -n "$WALL_PATH" ]; then
    sed -i "9s|.*|\$wallpaper = $WALL_PATH|" ~/.config/hypr/hyprlock.conf
fi

/usr/bin/hyprlock
