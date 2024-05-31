#!/bin/bash
  
# Define CPU lists for each service
trafficserver_cpu_list="1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,41,43,45,47,49,51,53,55,57,59,61,63,65,67,69,71,73,75,77,79,81,83,85,87,89,91,93,95"  # Example CPU list for trafficserver
fluentbit_cpu_list="44,46,92,94"       # Example CPU list for fluent-bit
node_exporter_cpu_list="42,90"  # Example CPU list for node_exporter
crowdsec_cpu_list="34,36,38,40,82,84,86,88"

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
#change_affinity "crowdsec" "$crowdsec_cpu_list"

echo "Service CPU affinities configured successfully."
