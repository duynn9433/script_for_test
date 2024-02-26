#!/bin/bash

# Function to display help
display_help() {
   echo "Usage: $0 <jar_file_path> <logging_level> <server_port> <additional_jmeter_args>"
   echo "Example: $0 DistributedJmeter-0.0.1-SNAPSHOT.jar DEBUG/INFO 8888 "
}

# Check if the first argument is --help
if [ "$1" = "--help" ]; then
   display_help
   exit 0
fi

# Assign default values if arguments are not provided
JAR_FILE="${1:-DistributedJmeter-0.0.1-SNAPSHOT.jar}"
LOGGING_LEVEL="${2:-DEBUG}"
SERVER_PORT="${3:-8888}"
ADDITIONAL_JMETER_ARGS="${4:---jmeter.pass113=Jgv_113H3J! --jmeter.pass114=Vxc_11455J! --jmeter.pass115=Ora_11574J!}"
echo "${ADDITIONAL_JMETER_ARGS}"

# Check if JAR file exists
if [ ! -f "$JAR_FILE" ]; then
    echo "Error: JAR file '$JAR_FILE' not found."
    exit 1
fi

# Execute the Java JAR file with provided arguments
java -jar "$JAR_FILE" --logging.level.root="$LOGGING_LEVEL" --server.port="$SERVER_PORT" "$ADDITIONAL_JMETER_ARGS"
