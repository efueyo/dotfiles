#!/bin/bash

# Collect active WireGuard VPNs
wg_conns=$(nmcli connection show --active 2>/dev/null | grep vpn | awk '{print $1}')

# Collect active openvpn3 sessions
ovpn_conns=$(openvpn3 sessions-list 2>/dev/null | grep "Config name:" | awk -F': ' '{print $2}' | xargs -n1)

# Combine into single list
all_vpns=$(printf "%s\n%s" "$wg_conns" "$ovpn_conns" | grep -v '^$')
count=$(echo "$all_vpns" | grep -c .)

if [ "$count" -eq 0 ]; then
    echo '{"tooltip":"VPN Disconnected","class":"disconnected"}'
elif [ "$count" -eq 1 ]; then
    name=$(echo "$all_vpns" | head -1)
    echo "{\"tooltip\":\"VPN: $name\",\"class\":\"connected\"}"
else
    names=$(echo "$all_vpns" | paste -sd', ')
    echo "{\"tooltip\":\"VPNs: $names\",\"class\":\"stacked\"}"
fi
