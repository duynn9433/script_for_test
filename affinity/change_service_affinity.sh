#!/bin/bash

# Function to check if a string is a valid number
is_number() {
    [[ $1 =~ ^[0-9]+$ ]]
}

# Function to expand CPU number ranges (e.g., "0-3") into a comma-separated list
expand_cpu_range() {
    local cpu_range=$1
    local expanded_range=""

    for range in $(echo "$cpu_range" | tr ',' ' '); do
        if [[ "$range" =~ ^[0-9]+-[0-9]+$ ]]; then
            start=$(echo "$range" | cut -d'-' -f1)
            end=$(echo "$range" | cut -d'-' -f2)
            for ((i = $start; i <= $end; i++)); do
                expanded_range="$expanded_range$i,"
            done
        elif [[ "$range" =~ ^[0-9]+$ ]]; then
            expanded_range="$expanded_range$range,"
        else
            echo "Error: Invalid CPU range '$range'." >&2
            exit 1
        fi
    done

    echo "${expanded_range%,}"  # Remove the trailing comma
}

# Function to validate CPU affinity input
validate_cpu_affinity() {
    local cpu_affinity=$1
    local cpu_count=$(nproc)

    # Expand CPU number ranges into a comma-separated list
    local expanded_affinity=$(expand_cpu_range "$cpu_affinity")

    # Validate each CPU number in the list
    for cpu in $(echo "$expanded_affinity" | tr ',' ' '); do
        if [[ "$cpu" =~ ^[0-9]+$ ]]; then
            if [ "$cpu" -ge "$cpu_count" ]; then
                echo "Error: CPU $cpu exceeds the maximum available CPUs ($cpu_count)." >&2
                exit 1
            fi
        else
            echo "Error: Invalid CPU number '$cpu'." >&2
            exit 1
        fi
    done

    echo "$expanded_affinity"
}

# Main script
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <service_name> <cpu_affinity>"
    echo "Example: $0 myservice 0,1,2,5-48"
    exit 1
fi

service_name=$1
cpu_affinity=$2

# Validate CPU affinity input
expanded_cpu_affinity=$(validate_cpu_affinity "$cpu_affinity")

# Find the unit file
unit_file=$(systemctl show -p FragmentPath --value "$service_name")

if [ -z "$unit_file" ]; then
    echo "Error: Service '$service_name' not found." >&2
    exit 1
fi

# Check if CPUAffinity is already defined in the unit file
if grep -q "^CPUAffinity=" "$unit_file"; then
    # CPUAffinity is already defined, so replace its value
    echo "CPUAffinity already defined in unit file. Updating..."
    sudo sed -i "s/^CPUAffinity=.*/CPUAffinity=$expanded_cpu_affinity/" "$unit_file"
else
    # CPUAffinity is not defined, so add it
    echo "CPUAffinity not defined in unit file. Adding..."
    sudo sed -i "/^\[Service\]/a CPUAffinity=$expanded_cpu_affinity" "$unit_file"
fi

# Reload systemd daemon
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

# Restart the service
echo "Restarting service: $service_name"
sudo systemctl restart "$service_name"

echo "CPU affinity set successfully."
