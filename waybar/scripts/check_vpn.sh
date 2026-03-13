#!/bin/bash

# Check WireGuard/nmcli VPN
wg_conn=$(nmcli connection show --active 2>/dev/null | grep vpn | awk '{print $1}')

# Check openvpn3 sessions
ovpn_conn=$(openvpn3 sessions-list 2>/dev/null | grep "Config name:" | awk -F': ' '{print $2}' | xargs)

if [ -n "$wg_conn" ]; then
    echo "{\"tooltip\":\"VPN: $wg_conn\",\"class\":\"connected\"}"
elif [ -n "$ovpn_conn" ]; then
    echo "{\"tooltip\":\"VPN: $ovpn_conn\",\"class\":\"connected\"}"
else
    echo '{"tooltip":"VPN Disconnected","class":"disconnected"}'
fi







