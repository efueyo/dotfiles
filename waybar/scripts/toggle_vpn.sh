#!/bin/bash

# --- Detect active VPNs ---
active_wg=$(nmcli connection show --active 2>/dev/null | grep "wireguard" | awk '{print $1}')

# Build associative array: ovpn config name -> session path
declare -A ovpn_paths
cpath=""
while IFS= read -r line; do
    if [[ "$line" =~ "Path:" ]]; then
        cpath=$(echo "$line" | awk '{print $2}')
    fi
    if [[ "$line" =~ "Config name:" ]]; then
        cname=$(echo "$line" | awk -F': ' '{print $2}' | xargs)
        [ -n "$cpath" ] && ovpn_paths["$cname"]="$cpath"
        cpath=""
    fi
done < <(openvpn3 sessions-list 2>/dev/null)

# --- Sudo password (needed for wg listing and wg-quick) ---
mypass=$(rofi -dmenu -password --no-fixed-num-lines -p "Sudo password: ")
[ -z "$mypass" ] && exit 0

# --- Gather all available configs ---
wg_configs=$(echo "$mypass" | sudo -S ls /etc/wireguard/ 2>/dev/null | sed 's/.conf//g')
ovpn_configs=$(openvpn3 configs-list --json 2>/dev/null | jq -r 'to_entries[].value.name // empty' 2>/dev/null)

# --- Build menu ---
menu=""

while IFS= read -r name; do
    [ -z "$name" ] && continue
    if echo "$active_wg" | grep -qx "$name"; then
        menu+="● [wg] $name\n"
    else
        menu+="○ [wg] $name\n"
    fi
done <<< "$wg_configs"

while IFS= read -r name; do
    [ -z "$name" ] && continue
    if [ -n "${ovpn_paths[$name]}" ]; then
        menu+="● [ovpn] $name\n"
    else
        menu+="○ [ovpn] $name\n"
    fi
done <<< "$ovpn_configs"

# Sort: connected first (● sorts after ○)
menu=$(echo -e "$menu" | grep -v '^$' | sort -r)

CHOSEN=$(echo -e "$menu" | rofi -dmenu -p "VPN: ")
[ -z "$CHOSEN" ] && exit 0

status=$(echo "$CHOSEN" | awk '{print $1}')
type=$(echo "$CHOSEN" | awk '{print $2}')
name=$(echo "$CHOSEN" | cut -d' ' -f3-)

if [ "$status" = "●" ]; then
    # Disconnect
    if [ "$type" = "[wg]" ]; then
        echo "$mypass" | sudo -S wg-quick down "$name"
    elif [ "$type" = "[ovpn]" ]; then
        openvpn3 session-manage --disconnect --path "${ovpn_paths[$name]}"
    fi
else
    # Connect
    if [ "$type" = "[wg]" ]; then
        echo "$mypass" | sudo -S wg-quick up "$name"
    elif [ "$type" = "[ovpn]" ]; then
        wezterm start -- bash -c '
        export PATH=$PATH:$HOME/bin/
        export BW_SESSION=$(bw unlock --raw)
        bw_item=$(bw_view_item)
        bw_user=$(echo "$bw_item" | jq -r .login.username)
        bw_pass=$(echo "$bw_item" | jq -r .login.password)
        bw_totp=$(echo "$bw_item" | jq -r .login.totp)
        echo "Generating one time password..."
        [ -n "$bw_totp" ] && bw_totp=$(bw get totp "$(echo "$bw_item" | jq -r .id)" 2>/dev/null)
        printf "%s\\n%s\\n%s\\n" "$bw_user" "$bw_pass" "$bw_totp" | openvpn3 session-start --config '"$name"'
        '
    fi
fi
