#!/bin/bash

# --- Early Exit for AC Power ---
if [ "$(cat /sys/class/power_supply/AC/online 2>/dev/null)" = "1" ]; then
    if [ "$(powerprofilesctl get)" = "power-saver" ]; then
        powerprofilesctl set balanced
    fi
    echo "NORMAL" > "/tmp/battery_monitor_state"
    exit 0
fi

# Thresholds
SAVER=30
LOW=20
CRITICAL=10
DANGER=5
STATE_FILE="/tmp/battery_monitor_state"

# Battery Info
BAT_PATH="/sys/class/power_supply/BAT0"
STATUS=$(cat "$BAT_PATH/status")
CAPACITY=$(cat "$BAT_PATH/capacity")

[ -f "$STATE_FILE" ] && PREV_STATE=$(cat "$STATE_FILE") || PREV_STATE="NORMAL"

# Reset if charging
if [ "$STATUS" = "Charging" ] || [ "$STATUS" = "Full" ]; then
    makoctl dismiss --all
    powerprofilesctl set balanced
    echo "NORMAL" > "$STATE_FILE"
    exit 0
fi

# --- Logic for Notifications and Power Profiles ---
# 1. Danger (5%)
if [ "$CAPACITY" -le "$DANGER" ]; then
    if [ "$PREV_STATE" != "DANGER" ]; then
        notify-send -u critical -c "battery-danger" "⚠️ Emergency" "Battery at $CAPACITY%. Suspending system now..."
        echo "DANGER" > "$STATE_FILE"
        sleep 30 && systemctl suspend
    fi
# 2. Critical (10%)
elif [ "$CAPACITY" -le "$CRITICAL" ]; then
    if [ "$PREV_STATE" != "CRITICAL" ]; then
        notify-send -u critical -c "battery-critical" "‼️ Critical Warning" "Battery at $CAPACITY%. Please plug in the charger immediately."
        echo "CRITICAL" > "$STATE_FILE"
    fi
# 3. Low (20%)
elif [ "$CAPACITY" -le "$LOW" ]; then
    if [ "$PREV_STATE" != "LOW" ]; then
        notify-send -u normal -c "battery-low" "💡 Low Battery" "Battery level is $CAPACITY%."
        echo "LOW" > "$STATE_FILE"
    fi
# 4. Power Saver (30%) - NEW
elif [ "$CAPACITY" -le "$SAVER" ]; then
    if [ "$PREV_STATE" != "SAVER" ]; then
        powerprofilesctl set power-saver
        notify-send -u normal -c "battery-low" "🔋 Power Saving Mode" "Battery at $CAPACITY%. Switched to power-saver profile."
        echo "SAVER" > "$STATE_FILE"
    fi
else
    echo "NORMAL" > "$STATE_FILE"
fi

