#!/bin/bash

# Path to the HAProxy configuration file
DEFAULT_CONFIG_FILE="$(dirname "$0")/haproxy.conf"

# Function to print messages when verbose mode is enabled
verbose_echo() {
    if [ "$VERBOSE" = true ]; then
        echo "$@"
    fi
}

# Function to display help message
show_help() {
    echo "Usage: $0 [-v] [-h] [haproxy_conf_file]"
    echo ""
    echo "Options:"
    echo "  -v      Enable verbose mode."
    echo "  -h      Show this help message."
    echo ""
    echo "Arguments:"
    echo "  haproxy_conf_file  The path to the HAProxy configuration file. Default: $DEFAULT_CONFIG_FILE"
}

# Parse options
while getopts ":vh" option; do
    case $option in
        v)
            VERBOSE=true
            ;;
        h)
            show_help
            exit 0
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

# Use the provided argument as the path to the HAProxy configuration file
HAPROXY_CONF_FILE=${1:-"$DEFAULT_CONFIG_FILE"}

# Check if the HAProxy configuration file exists
if [ ! -f "$HAPROXY_CONF_FILE" ]; then
    echo "Error: HAProxy configuration file not found: $HAPROXY_CONF_FILE"
    exit 1
fi

# Define the HAProxy service file content
SERVICE_FILE_CONTENT="[Unit]
Description=HAProxy Load Balancer
After=syslog.target network.target

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/haproxy
ExecStart=/usr/local/sbin/haproxy -f $CONFIG_FILE -p $PID_FILE $CLI_OPTIONS
ExecReload=/bin/kill -USR2 $MAINPID
ExecStop=/bin/kill -USR1 $MAINPID
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target"

# Path to the HAProxy service file
SERVICE_FILE_PATH="/etc/systemd/system/haproxy.service"

# Define the HAProxy environment file content
ENV_FILE_CONTENT="# Command line options to pass to HAProxy at startup
# The default is:
CLI_OPTIONS=\"-Ws\"

# Specify an alternate configuration file. The default is:
CONFIG_FILE=/etc/haproxy/haproxy.cfg

# File used to track process IDs. The default is:
PID_FILE=/var/run/haproxy.pid"

# Path to the HAProxy environment file
ENV_FILE_PATH="/etc/sysconfig/haproxy"

# Copy HAProxy configuration file
verbose_echo "Copying HAProxy configuration file to /etc/haproxy/haproxy.cfg..."
sudo cp "$HAPROXY_CONF_FILE" /etc/haproxy/haproxy.cfg

# Create the HAProxy service file
verbose_echo "Creating the HAProxy service file at $SERVICE_FILE_PATH..."
echo "$SERVICE_FILE_CONTENT" | sudo tee "$SERVICE_FILE_PATH" > /dev/null

# Create the HAProxy environment file
verbose_echo "Creating the HAProxy environment file at $ENV_FILE_PATH..."
echo "$ENV_FILE_CONTENT" | sudo tee "$ENV_FILE_PATH" > /dev/null

# Reload systemd to apply the new service
verbose_echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

# Enable the HAProxy service to start at boot
verbose_echo "Enabling the HAProxy service to start at boot..."
sudo systemctl enable haproxy

# Start the HAProxy service
verbose_echo "Starting the HAProxy service..."
sudo systemctl start haproxy

echo "HAProxy service has been created and started."
