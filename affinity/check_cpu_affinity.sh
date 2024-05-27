#!/bin/bash

# Define colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print CPU affinity of a service
print_affinity() {
    local target=$1
    local pid_list=$(pidof $target)

    if [ -z "$pid_list" ]; then
        echo -e "${YELLOW}$target is not running.${NC}"
        return
    fi

    echo -e "${BLUE}================ Affinity for $target =================${NC}"

    # Loop through each PID and print its affinity
    for pid in $pid_list; do
        echo -e "${GREEN}------------------------------------------------${NC}"
        taskset -cp $pid
        echo Number of thread && ps -o nlwp= -p $pid
    done
}

# Function to print CPU affinity of all network interfaces
print_network_affinity() {
    echo -e "${BLUE}================ CPU affinity for network interfaces with IRQ numbers =================${NC}"
    for interface in $(ls /sys/class/net); do
        irqs=$(cat /proc/interrupts | grep "$interface" | awk -F ":" '{print $1}' | tr -d ' ')
        if [ -n "$irqs" ]; then
            echo -e "${GREEN}------------------------------------------------${NC}"
            echo "Interface: $interface"
            for irq in $irqs; do
                affinity_list=$(cat /proc/irq/$irq/smp_affinity_list)
                formatted_list=$(echo $affinity_list | awk '{gsub(/\s+/, ""); gsub(/\n/, ", "); print}' | sed 's/^/[(/' | sed 's/$/)]/' | sed 's/, $//')
                echo "IRQ: $irq - SMP Affinity List: $formatted_list"
            done
        fi
    done
}

# Function to call the bash script affinity_irq_NIC.sh
call_custom_script() {
    local script_name="affinity_irq_NIC.sh"
    if [ -f "$script_name" ]; then
        echo -e "${BLUE}================ Calling custom script: $script_name =================${NC}"
        ./$script_name
    else
        echo -e "${YELLOW}Custom script $script_name not found.${NC}"
    fi
}

# Main menu function
main_menu() {
    echo "Select an option:"
    echo "1. Check CPU affinity of HAProxy"
    echo "2. Check CPU affinity of Apache Traffic Server (traffic_server and traffic_manager)"
    echo "3. Check CPU affinity of a custom service"
    echo "4. Check CPU affinity of network interfaces with IRQ numbers"
    echo "5. Call a custom bash script (affinity_irq_NIC.sh)"
    echo "6. Exit"

    read -p "Enter your choice: " choice

    case $choice in
        1) print_affinity "haproxy";;
        2) 
            print_affinity "traffic_server"
            print_affinity "traffic_manager";;
        3) read -p "Enter service name: " custom_service
           print_affinity $custom_service;;
        4) print_network_affinity;;
        5) call_custom_script;;
        6) exit;;
        *) echo "Invalid choice";;
    esac

    # Prompt to continue or exit
    read -p "Press Enter to continue (opt: clear) or type 'exit' to quit: " cont
    if [ "$cont" != "exit" ]; then
        if [ "$cont" == "clear" ]; then
           clear
        fi
        main_menu
    fi
}

# Start the main menu
main_menu
