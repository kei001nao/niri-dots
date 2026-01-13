#!/bin/bash

# options="⏻ Shutdown\n🔄 Reboot\n🌙 Suspend\n   Logout"
options="　🌙　Suspend\n　🔄　Reboot\n　⏻　 Shutdown\n　　　Logout"

selected=$(echo -en "$options" | vicinae dmenu -p ">" --width 200 --height 240 --no-section)

#selected=$(cat <<EOF | vicinae dmenu -p "System:" --width 200 --height 300
#⏻ Shutdown
#🔄 Reboot
#🌙 Suspend
#   Logout
#EOF
#)

case "$selected" in
    "　⏻　 Shutdown")
        systemctl poweroff
        ;;
    "　🔄　Reboot")
        systemctl reboot
        ;;
    "　🌙　Suspend")
        systemctl suspend
        ;;
    "　　　Logout")
        niri msg action quit
        ;;
esac
