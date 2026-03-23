#!/bin/bash

# 20-20-20 rule: every 20 minutes, look at something 20 feet away for 20 seconds
# Tracks time via a state file, resets on click

STATE_FILE="/tmp/waybar-eye-break"
INTERVAL_SEC=1200 # 20 minutes

# Click resets the timer
if [ "$1" = "reset" ]; then
    date +%s > "$STATE_FILE"
    exit 0
fi

# Initialize state file if missing
if [ ! -f "$STATE_FILE" ]; then
    date +%s > "$STATE_FILE"
fi

last_reset=$(cat "$STATE_FILE")
now=$(date +%s)
elapsed=$((now - last_reset))
remaining=$((INTERVAL_SEC - elapsed))

if [ "$remaining" -le -600 ]; then
    # 30+ minutes: blink urgently
    minutes_overdue=$(( (-remaining) / 60 ))
    echo "{\"tooltip\":\"Break time! (${minutes_overdue}m overdue) - click to reset\",\"class\":\"urgent\"}"
elif [ "$remaining" -le 0 ]; then
    # 20-30 minutes: red
    minutes_overdue=$(( (-remaining) / 60 ))
    echo "{\"tooltip\":\"Break time! (${minutes_overdue}m overdue) - click to reset\",\"class\":\"break\"}"
else
    mins=$((remaining / 60))
    secs=$((remaining % 60))
    printf '{"tooltip":"Next eye break in %02d:%02d","class":"ok"}\n' "$mins" "$secs"
fi
