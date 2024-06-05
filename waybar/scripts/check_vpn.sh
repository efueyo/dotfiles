#! /bin/bash

# Detect if the VPN is connected


# Get the list of available VPN connections

conns=$(nmcli connection show --active | grep vpn | awk '{print $1}')

if [ -z "$conns" ]; then
    echo '{"tooltip":"VPN Disconnected","class":"disconnected"}'
else
    echo '{"tooltip":"VPN: '$conns'","class":"connected"}'
fi







