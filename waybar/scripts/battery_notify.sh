#!/bin/bash

# Sends notifications when battery is low
# Designed to run as a waybar custom module (interval-based)

WARN_LEVEL=30
CRIT_LEVEL=15

capacity=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo 100)
status=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo "Unknown")

if [ "$status" != "Charging" ] && [ "$status" != "Full" ]; then
    if [ "$capacity" -le "$CRIT_LEVEL" ]; then
        notify-send -u critical -i battery-empty \
            "Battery Critical" \
            "Battery at ${capacity}% — plug in now!" \
            -h string:x-canonical-private-synchronous:battery-warn
    elif [ "$capacity" -le "$WARN_LEVEL" ]; then
        notify-send -u normal -i battery-low \
            "Battery Low" \
            "Battery at ${capacity}%" \
            -h string:x-canonical-private-synchronous:battery-warn
    fi
fi
