#!/bin/bash

# Check active VPNs
CURRENT_WG=$(nmcli connection show --active 2>/dev/null | grep "wireguard" | awk '{ print $1 }')
CURRENT_OVPN_PATH=$(openvpn3 sessions-list 2>/dev/null | grep "Path:" | awk '{print $2}' | head -1)

# If WireGuard is active, disconnect it
if [ -n "$CURRENT_WG" ]; then
    mypass=$(rofi -dmenu -password --no-fixed-num-lines -p "Sudo password: ")
    echo "$mypass" | sudo -S wg-quick down "$CURRENT_WG"
    exit 0
fi

# If openvpn3 session is active, disconnect it
if [ -n "$CURRENT_OVPN_PATH" ]; then
    openvpn3 session-manage --disconnect --path "$CURRENT_OVPN_PATH"
    exit 0
fi

# No VPN active — build config list (openvpn3 first, then wireguard)
ovpn_configs=$(openvpn3 configs-list --json 2>/dev/null | jq -r 'to_entries[].value.name // empty' 2>/dev/null | sed 's/^/[ovpn] /')

mypass=$(rofi -dmenu -password --no-fixed-num-lines -p "Sudo password: ")
wg_configs=$(echo "$mypass" | sudo -S ls /etc/wireguard/ 2>/dev/null | sed 's/.conf//g' | sed 's/^/[wg] /')

all_configs=$(printf "%s\n%s" "$ovpn_configs" "$wg_configs" | grep -v '^$')
CHOSEN=$(echo "$all_configs" | rofi -dmenu -p "VPN Config: ")

[ -z "$CHOSEN" ] && exit 0

type=$(echo "$CHOSEN" | awk '{print $1}')
name=$(echo "$CHOSEN" | cut -d' ' -f2-)

if [ "$type" = "[ovpn]" ]; then
    wezterm start -- openvpn3 session-start --config "$name"
elif [ "$type" = "[wg]" ]; then
    echo "$mypass" | sudo -S wg-quick up "$name"
fi
