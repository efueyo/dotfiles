#!/bin/bash

# Get the list of available Wi-Fi networks
# The awk command removes duplicate entries and empty lines
# some LLM and + https://github.com/zbaylin/rofi-wifi-menu/blob/master/rofi-wifi-menu.sh



NETWORKS=$(nmcli --fields "SSID,SECURITY" device wifi list | sed '/^--/d' | sed '/^SSID/d' | awk '{print "   " $0}')
KNOWNCON=$(nmcli -t -f NAME,TYPE connection show | awk -F: '$2=="802-11-wireless"{print $1}')

STATUS=$(nmcli -t -fields WIFI g)
CURRSSID=$(nmcli -t -f active,ssid dev wifi | awk -F: '$1 ~ /^yes/ {print $2}')

OFF_MSG="󱚼   Toggle off"
ON_MSG="󱚽   Toggle on"
if [[ "$STATUS" =~ "enabled" ]]; then
	TOGGLE=$OFF_MSG
elif [[ "$STATUS" =~ "disabled" ]]; then
	TOGGLE=$ON_MSG
fi


CHENTRY=$(echo -e "$TOGGLE\n$NETWORKS" | uniq -u | rofi -dmenu -p "Wi-Fi SSID: ")


CHSSID=$(echo "$CHENTRY" | sed  's/\s\{2,\}/\|/g' | awk -F "|" '{print $2}')

if [ "$CHENTRY" = "$ON_MSG" ]; then
	nmcli radio wifi on
elif [ "$CHENTRY" = "$OFF_MSG" ]; then
	nmcli radio wifi off
else
	echo "Connecting to $CHSSID"
  if echo "$KNOWNCON" | grep -q "^${CHSSID}$"; then
    nmcli con up "$CHSSID"
  else
    WIFIPASS=$(echo "Type your Password. No options here." | rofi -dmenu -p "password: " -lines 1 -font "$FONT" )
    if [ -z "$WIFIPASS" ]; then
      echo "No password provided"
      nmcli device wifi connect "$CHSSID"
    else
      nmcli device wifi connect "$CHSSID" password "$WIFIPASS"
    fi
  fi
fi
