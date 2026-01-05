#!/bin/bash

options="　Update\n　Settings\n　Install\n　Remove\n　Theme\n　Power Menu"

selected=$(echo -en "$options" | vicinae dmenu -p ">" --no-section --width 200 --height 320)

case "$selected" in
    "　Update")
        kitty --app-id kitty-floating -e arch-update
        ;;
    "　Settings")
        $HOME/.config/scripts/vicinae-settings-menu.sh
        ;;
    "　Install")

        ;;
    "　Remove")

        ;;
    "　Theme")

        ;;
    "　Power Menu")
        $HOME/.config/scripts/vicinae-power-menu.sh
        ;;
esac
