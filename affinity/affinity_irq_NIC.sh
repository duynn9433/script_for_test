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
interface_cpu_map=( ["ens1f0np0"]="18,20,22,24,66,68,70,72" ["ens2f0np0"]="18,20,22,24,66,68,70,72" ["ens1f1np1"]="26,28,30,32,74,76,78,80" ["ens2f1np1"]="26,28,30,32,74,76,78,80" )

# Set IRQs to irqbalance ban list
set_irqbalance_ban_irqs() {
    local irqbalance_config="/etc/sysconfig/irqbalance"
    local banirqs=""

    for cpus in "${interface_cpu_map[@]}"; do
        local irq_numbers=($(get_irq_numbers $interface))
        for irq in "${irq_numbers[@]}"; do
            banirqs+="--banirq=$irq "
        done
    done

    # Set the IRQBALANCE_ARGS with the new banirq list
    if grep -q "^IRQBALANCE_ARGS=" "$irqbalance_config"; then
        sudo sed -i "s|^IRQBALANCE_ARGS=.*|IRQBALANCE_ARGS=\"$banirqs\"|" "$irqbalance_config"
    else
        echo "IRQBALANCE_ARGS=\"$banirqs\"" | sudo tee -a "$irqbalance_config" > /dev/null
    fi

    # Restart irqbalance to apply the new configuration
    sudo systemctl restart irqbalance
}

# Set banned CPUs to irqbalance configuration
set_banned_cpus_to_irqbalance() {
    local banned_cpus="$1"
    local irqbalance_config="/etc/sysconfig/irqbalance"

    if grep -q "^IRQBALANCE_BANNED_CPU_LIST=" "$irqbalance_config"; then
        sudo sed -i "s|^IRQBALANCE_BANNED_CPU_LIST=.*|IRQBALANCE_BANNED_CPU_LIST=\"$banned_cpus\"|" "$irqbalance_config"
    else
        echo "IRQBALANCE_BANNED_CPU_LIST=\"$banned_cpus\"" | sudo tee -a "$irqbalance_config" > /dev/null
    fi
}

# Set IRQ affinity for interfaces
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

# Set banned CPUs
BANNED_CPUS_LIST="1,3,5,7-47,49,51,53,55-95"
set_banned_cpus_to_irqbalance "$BANNED_CPUS_LIST"

# Set IRQs to irqbalance ban list
set_irqbalance_ban_irqs

# Debug: Print full irqbalance config for verification
echo "irqbalance configuration:"
cat /etc/sysconfig/irqbalance

# Perform CPU affinity assignment and verification for each interface
for interface in "${!interface_cpu_map[@]}"; do
    cpus=${interface_cpu_map[$interface]}
    echo "Setting IRQ affinity for $interface to CPUs $cpus"
    set_irq_affinity $interface $cpus
    echo "Verifying IRQ affinity for $interface"
    verify_affinity $interface $cpus
done

echo "All interfaces have been successfully configured and IRQs added to irqbalance ban list."
