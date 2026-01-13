#!/bin/bash

# options="⏻ Shutdown\n🔄 Reboot\n🌙 Suspend\n   Logout"
options="　Network\n　Bluetooth\n　Sound"

selected=$(echo -en "$options" | vicinae dmenu -p ">" --no-section --width 200 --height 200)

#selected=$(cat <<EOF | vicinae dmenu -p "System:" --width 200 --height 300
#⏻ Shutdown
#🔄 Reboot
#🌙 Suspend
#   Logout
#EOF
#)

case "$selected" in
    "　Network")
        kitty --app-id=impala -e impala
        # vicinae vicinae://extensions/sovereign/wifi-commander/scan-wifi
        ;;
    "　Bluetooth")
        kitty --app-id=bluetui -e bluetui
        ;;
    "　Sound")
        pavucontrol -t 1
        ;;
esac
