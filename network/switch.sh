#!/bin/bash

# Define the network interface that should enable proxy automatically
PROXY_INTERFACE="eno2"

# Function to get current network status
show_status() {
    echo "Current network interface status:"
    interfaces=($(ls /sys/class/net | grep -v -E '^(lo|docker|veth|tun|tap|br-|wl+|virbr|vmnet|bond|dummy|sit|ip6tnl|ib)'))
    for iface in "${interfaces[@]}"; do
        state=$(nmcli device status | awk -v iface="$iface" '$1 == iface {print $3}')
        echo "$iface: ${state:-disconnected}"
    done
    echo ""
    proxy_mode=$(gsettings get org.gnome.system.proxy mode)
    echo "Current Proxy Mode: $proxy_mode"
}

# Function to configure proxy settings
set_proxy() {
    if [[ "$1" == "on" ]]; then
        echo "Enabling proxy..."
        gsettings set org.gnome.system.proxy mode 'manual'
    elif [[ "$1" == "off" ]]; then
        echo "Disabling proxy..."
        gsettings set org.gnome.system.proxy mode 'none'
    fi
}

# Function to enable proxy if the selected network matches PROXY_INTERFACE
check_proxy_for_interface() {
    if [[ "$1" == "$PROXY_INTERFACE" ]]; then
        set_proxy "on"
    else
        set_proxy "off"
    fi
}

# Function to connect to a network using nmcli
connect_network() {
    type=$(nmcli -t -f DEVICE,TYPE device | grep "^$1:" | cut -d: -f2)
    
    if [[ "$type" == "wifi" ]]; then
        echo "Reconnecting WiFi ($1) using saved profile..."
        nmcli connection up "$1"
    else
        echo "Connecting to wired network ($1)..."
        nmcli device connect "$1"
    fi
    
    check_proxy_for_interface "$1"
}


# Function to disconnect a network using nmcli
disconnect_network() {
    type=$(nmcli -t -f DEVICE,TYPE device | grep "^$1:" | cut -d: -f2)
    
    if [[ "$type" == "wifi" ]]; then
        echo "Disconnecting WiFi ($1) using NetworkManager profile..."
        nmcli connection down "$1"
    else
        echo "Disconnecting wired network ($1)..."
        nmcli device disconnect "$1"
    fi
}


# Handle command-line options
if [[ "$1" == "--status" ]]; then
    show_status
    exit 0
elif [[ "$1" == "--proxy" && ( "$2" == "on" || "$2" == "off" ) ]]; then
    set_proxy "$2"
    exit 0
fi

# Get the list of physical network interfaces
interfaces=($(ls /sys/class/net | grep -v -E '^(lo|docker|veth|tun|tap|br-|wl+|virbr|vmnet|bond|dummy|sit|ip6tnl|ib)'))

# Check if no interfaces are found
if [[ ${#interfaces[@]} -eq 0 ]]; then
    echo "No physical network interfaces found."
    exit 1
fi

# Get the connection status (CONNECTED/DISCONNECTED) using nmcli
echo "Checking network interface status..."
active_interfaces=()
for iface in "${interfaces[@]}"; do
    state=$(nmcli device status | awk -v iface="$iface" '$1 == iface {print $3}')
    echo "$iface: ${state:-disconnected}"
    if [[ "$state" == "connected" ]]; then
        active_interfaces+=("$iface")
    fi
done
echo ""

# Handle cases based on the number of available interfaces
case ${#interfaces[@]} in
    1)
        echo "Only one network interface found: ${interfaces[0]}. Enabling it..."
        connect_network "${interfaces[0]}"
        ;;
    
    2)
        if [[ ${#active_interfaces[@]} -eq 0 ]]; then
            connect_network "${interfaces[0]}"
            echo "No active networks found. Enabling: ${interfaces[0]}"
        elif [[ ${#active_interfaces[@]} -eq 1 ]]; then
            for iface in "${interfaces[@]}"; do
                if [[ "$iface" != "${active_interfaces[0]}" ]]; then
                    disconnect_network "${active_interfaces[0]}"
                    connect_network "$iface"
                    echo "Switched from ${active_interfaces[0]} to $iface"
                    exit 0
                fi
            done
        elif [[ ${#active_interfaces[@]} -eq 2 ]]; then
            echo "Both networks are active. Disabling all..."
            for iface in "${active_interfaces[@]}"; do
                disconnect_network "$iface"
            done
            echo "All networks have been disconnected."

            echo "Available network interfaces:"
            for i in "${!interfaces[@]}"; do
                echo "$(($i + 1))) ${interfaces[$i]}"
            done

            while true; do
                read -p "Enter the number of the network to enable (1-2): " choice
                if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= 2 )); then
                    selected_iface="${interfaces[$((choice - 1))]}"
                    connect_network "$selected_iface"
                    echo "Enabled network: $selected_iface"
                    break
                else
                    echo "Invalid selection. Please try again!"
                fi
            done
        fi
        ;;
    
    *)
        echo "Multiple network interfaces detected. Disabling all..."
        for iface in "${interfaces[@]}"; do
            disconnect_network "$iface"
        done
        echo "All networks have been disconnected."

        echo "Available network interfaces:"
        for i in "${!interfaces[@]}"; do
            echo "$(($i + 1))) ${interfaces[$i]}"
        done

        while true; do
            read -p "Enter the number of the network to enable (1-${#interfaces[@]}): " choice
            if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#interfaces[@]} )); then
                selected_iface="${interfaces[$((choice - 1))]}"
                connect_network "$selected_iface"
                echo "Enabled network: $selected_iface"
                break
            else
                echo "Invalid selection. Please try again!"
            fi
        done
        ;;
esac
