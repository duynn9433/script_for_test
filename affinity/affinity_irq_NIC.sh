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
interface_cpu_map=( ["eno1np0"]="0,1,2,3,4,5,6,7" )

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

    for i in "${!irq_numbers[@]}"; do
        local cpu_index=$((i % num_cpus))
        verbose_echo "Setting IRQ ${irq_numbers[$i]} affinity to CPU ${cpu_array[$cpu_index]}"
        echo ${cpu_array[$cpu_index]} > /proc/irq/${irq_numbers[$i]}/smp_affinity_list
    done
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

# Perform CPU affinity assignment and verification for each interface
for interface in "${!interface_cpu_map[@]}"; do
    cpus=${interface_cpu_map[$interface]}
    echo "Setting IRQ affinity for $interface to CPUs $cpus"
    set_irq_affinity $interface $cpus
    echo "Verifying IRQ affinity for $interface"
    verify_affinity $interface $cpus
done

echo "All interfaces have been successfully configured."
