#!/bin/bash
PIDFILE="/tmp/waybar-power-menu.pid"

# Check if another instance is running
if [ -f "$PIDFILE" ]; then
    OLD_PID=$(cat "$PIDFILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        # Kill the old instance and its fuzzel
        kill "$OLD_PID"
        pkill -P "$OLD_PID" fuzzel 2>/dev/null
        pkill fuzzel
        rm -f "$PIDFILE"
        exit 0
    fi
fi

# Store our PID
echo $$ > "$PIDFILE"

# Launch menu and get selection
SELECTION="$(
    printf " Lock\n󰤄 Suspend\n󰍃 Logout\n Reboot\n󰐥 Shutdown" \
    | fuzzel --dmenu -a top-right -l 5 -w 18 -p "Select an option: "
)"

# Clean up PID file after fuzzel closes
rm -f "$PIDFILE"

# Confirmation function
confirm_action() {
    local action="$1"
    local CONFIRMATION
    CONFIRMATION="$(
        printf "No\nYes" \
        | fuzzel --dmenu -a top-right -l 2 -w 18 -p "$action?"
    )"
    [[ "$CONFIRMATION" == *"Yes"* ]]
}

# Handle selection
case $SELECTION in
    *" Lock"*)
        hyprlock
        ;;

    *"󰤄 Suspend"*)
        if confirm_action "Suspend"; then
            systemctl suspend
        fi
        ;;

    *"󰍃 Logout"*)
        if confirm_action "Log out"; then
            loginctl terminate-user "$USER"
        fi
        ;;

    *" Reboot"*)
        if confirm_action "Reboot"; then
            systemctl reboot
        fi
        ;;

    *"󰐥 Shutdown"*)
        if confirm_action "Shutdown"; then
            systemctl poweroff
        fi
        ;;
esac
