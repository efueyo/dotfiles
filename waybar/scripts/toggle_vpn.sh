#!/bin/bash

# Get list of available configurations

mypass=$(rofi -dmenu -password --no-fixed-num-lines -p "Sudo password: ")

CURRENT_VPN=$(nmcli connection show --active | grep "wireguard" | awk '{ print $1 }')
echo $CURRENT_VPN

# if VPN is up, turn it off
if [ -n "$CURRENT_VPN" ]; then
    echo $mypass | sudo -S wg-quick down $CURRENT_VPN
    exit 0
fi

configs=$(echo $mypass | sudo -S ls /etc/wireguard/ | sed 's/.conf//g')

CHOSEN_VPN=$(echo -e "$configs" | uniq -u | rofi -dmenu -p "VPN Config: ")
echo $CHOSEN_VPN

if [ -n "$CHOSEN_VPN" ]; then
    echo $mypass | sudo -S wg-quick up $CHOSEN_VPN
    exit 0
fi
