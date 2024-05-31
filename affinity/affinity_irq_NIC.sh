#!/bin/bash

# Verbose mode control variable
VERBOSE=false

# Check command line argument to enable verbose mode
if [[ "$1" == "-v" || "$1" == "--verbose" ]]; then
    VERBOSE=true
fi

# Function to print information when verbose mode is enabled
verbose_echo() {
    if [ "$VERBOSE" = true ]; then
        echo "$@"
    fi
}

# Function to get the list of IRQs for an interface
get_irq_numbers() {
    local interface=$1
    local irq_numbers=$(cat /proc/interrupts | grep $interface | awk -F ":" '{print $1}' | tr -d ' ')
    echo $irq_numbers
}

# Define the interfaces and their corresponding CPUs
declare -A interface_cpu_map
#interface_cpu_map=( ["eno1np0"]="0,1,2,3,4,5,6,7" ["eno1np1"]="0,1,2,3,4,5,6,7" )
interface_cpu_map=( ["eno8303"]="40,88" ["eno8403"]="40,88" ["ens1f0np0"]="3,5,7,9,51,53,55,57" ["ens2f0np0"]="3,5,7,9,51,53,55,57" ["ens1f1np1"]="11,13,15,17,59,61,63,65" ["ens2f1np1"]="11,13,15,17,59,61,63,65" )

# Set CPU affinity for IRQs
set_irq_affinity() {
    local interface=$1
    local cpus=$2
    local irq_numbers=($(get_irq_numbers $interface))

    IFS=',' read -r -a cpu_array <<< "$cpus"

    verbose_echo "CPU array for $interface: ${cpu_array[@]}"
    verbose_echo "IRQ numbers for $interface: ${irq_numbers[@]}"

    local num_cpus=${#cpu_array[@]}
    local num_irqs=${#irq_numbers[@]}

    if [ $num_cpus -lt 1 ]; then
        echo "Error: No CPUs specified for $interface"
        exit 1
    fi
    if [ $num_cpus -ge $num_irqs ]; then
        for i in "${!irq_numbers[@]}"; do
            local cpu_index=$((i % num_cpus))
            verbose_echo "Setting IRQ ${irq_numbers[$i]} affinity to CPU ${cpu_array[$cpu_index]}"
            echo ${cpu_array[$cpu_index]} > /proc/irq/${irq_numbers[$i]}/smp_affinity_list
        done
    else 
        for i in "${!irq_numbers[@]}"; do
            verbose_echo "Setting IRQ ${irq_numbers[$i]} affinity to CPU ${cpu_array[@]}"
            echo ${cpu_array[@]} > /proc/irq/${irq_numbers[$i]}/smp_affinity_list
        done
    fi 
}

# Verify the CPU affinity assignment
verify_affinity() {
    local interface=$1
    local cpus=$2
    local irq_numbers=($(get_irq_numbers $interface))

    IFS=',' read -r -a cpu_array <<< "$cpus"

    verbose_echo "CPU array for $interface: ${cpu_array[@]}"
    verbose_echo "IRQ numbers for $interface: ${irq_numbers[@]}"

    local num_cpus=${#cpu_array[@]}

    for i in "${!irq_numbers[@]}"; do
        local cpu_index=$((i % num_cpus))
        local assigned_cpu=$(cat /proc/irq/${irq_numbers[$i]}/smp_affinity_list)
        verbose_echo "IRQ ${irq_numbers[$i]} for $interface is assigned to CPU $assigned_cpu"
        if [[ $assigned_cpu != ${cpu_array[$cpu_index]} ]]; then
            echo "Error: IRQ ${irq_numbers[$i]} for $interface is not correctly assigned to CPU ${cpu_array[$cpu_index]}"
            exit 1
        fi
    done

    echo "Affinity check passed for $interface"
}

# Function to add IRQs to irqbalance ban list
add_irqs_to_irqbalance_ban() {
    local irq_numbers=("$@")
    local irqbalance_config="/etc/default/irqbalance"
    local banirqs=""

    for irq in "${irq_numbers[@]}"; do
        banirqs+="$irq,"
    done

    # Remove trailing comma
    banirqs=${banirqs%,}

    # Check if the irqbalance config file already has OPTIONS set
    if grep -q "^OPTIONS=" "$irqbalance_config"; then
        # Append to existing OPTIONS line
        sudo sed -i "/^OPTIONS=/ s/\"$/ --banirq=$banirqs\"/" "$irqbalance_config"
    else
        # Add a new OPTIONS line
        echo "OPTIONS=\"--banirq=$banirqs\"" | sudo tee -a "$irqbalance_config" > /dev/null
    fi
}

# Function to add banned CPUs to irqbalance configuration
add_banned_cpus_to_irqbalance() {
    local banned_cpus="$1"
    local irqbalance_config="/etc/default/irqbalance"

    if grep -q "^IRQBALANCE_BANNED_CPU_LIST=" "$irqbalance_config"; then
        # Update existing BANNED_CPUS line
        sudo sed -i "s/^IRQBALANCE_BANNED_CPU_LIST=.*/IRQBALANCE_BANNED_CPU_LIST=\"$banned_cpus\"/" "$irqbalance_config"
    else
        # Add a new BANNED_CPUS line
        echo "IRQBALANCE_BANNED_CPU_LIST=\"$banned_cpus\"" | sudo tee -a "$irqbalance_config" > /dev/null
    fi
}

# Perform CPU affinity assignment and verification for each interface
for interface in "${!interface_cpu_map[@]}"; do
    cpus=${interface_cpu_map[$interface]}
    echo "Setting IRQ affinity for $interface to CPUs $cpus"
    set_irq_affinity $interface $cpus
    echo "Verifying IRQ affinity for $interface"
    verify_affinity $interface $cpus
done

# Collect all IRQs to be banned
all_irqs_to_ban=()

# Loop through each interface to get IRQs
for interface in "${!interface_cpu_map[@]}"; do
    irqs=($(get_irq_numbers $interface))
    all_irqs_to_ban+=("${irqs[@]}")
done

# Add the collected IRQs to irqbalance ban list
add_irqs_to_irqbalance_ban "${all_irqs_to_ban[@]}"

# Set banned CPUs
BANNED_CPUS_LIST="1,3,5,7-47,49,51,53,55-95"
add_banned_cpus_to_irqbalance "$BANNED_CPUS_LIST"

# Restart irqbalance to apply the new configuration
sudo systemctl restart irqbalance

echo "All interfaces have been successfully configured and IRQs added to irqbalance ban list."
