#!/bin/bash
  
# Define CPU lists for each service
trafficserver_cpu_list="19,21,23,25,27,29,31,33,35,37,39,41,43,45,47,67,69,71,73,75,77,79,81,83,85,87,89,91,93,95"  # Example CPU list for trafficserver
fluentbit_cpu_list="44,46,92,94"       # Example CPU list for fluent-bit
node_exporter_cpu_list="42,90"  # Example CPU list for node_exporter

# Function to change service affinity
change_affinity() {
    service_name=$1
    cpu_list=$2
    ./change_service_affinity.sh "$service_name" "$cpu_list"
}

# Set CPU affinities for each service
change_affinity "trafficserver" "$trafficserver_cpu_list"
change_affinity "fluent-bit" "$fluentbit_cpu_list"
change_affinity "node_exporter" "$node_exporter_cpu_list"

echo "Service CPU affinities configured successfully."
