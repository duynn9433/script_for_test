#!/bin/bash

# Function to print messages when verbose mode is enabled
verbose_echo() {
    if [ "$VERBOSE" = true ]; then
        echo "$@"
    fi
}

# Function to display help message
show_help() {
    echo "Usage: $0 [-v] [-h] [haproxy_source_url]"
    echo ""
    echo "Options:"
    echo "  -v      Enable verbose mode."
    echo "  -h      Show this help message."
    echo ""
    echo "Arguments:"
    echo "  haproxy_source_url  The URL to the HAProxy source file. Defaults to:"
    echo "                      https://www.haproxy.org/download/2.9/src/haproxy-2.9.7.tar.gz"
}

# Default HAProxy source URL
DEFAULT_URL="https://www.haproxy.org/download/2.9/src/haproxy-2.9.7.tar.gz"

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

# Use the provided argument as the URL or fall back to the default URL
HAPROXY_URL=${1:-$DEFAULT_URL}

# Define the working directory
WORKDIR="/home/vt_admin/Github"

# Install necessary development packages
verbose_echo "Installing necessary development packages..."
sudo yum install -y gcc make openssl-devel zlib-devel pcre-devel systemd-devel

# Check if the directory does not exist, create it
verbose_echo "Checking if the working directory exists..."
if [ ! -d "$WORKDIR" ]; then
    verbose_echo "Working directory does not exist. Creating $WORKDIR..."
    mkdir -p "$WORKDIR"
fi

# Change to the working directory
verbose_echo "Changing to the working directory $WORKDIR..."
cd "$WORKDIR"

# Download the HAProxy source file
verbose_echo "Downloading HAProxy source file from $HAPROXY_URL..."
wget "$HAPROXY_URL"

# Extract the filename from the URL
HAPROXY_FILE=${HAPROXY_URL##*/}
verbose_echo "Extracted filename: $HAPROXY_FILE"

# Extract the downloaded file
verbose_echo "Extracting the downloaded file $HAPROXY_FILE..."
tar -xvzf "$HAPROXY_FILE"

# Extract directory name from the tar.gz file (assuming standard naming)
HAPROXY_DIR=${HAPROXY_FILE%.tar.gz}
verbose_echo "Extracted directory name: $HAPROXY_DIR"

# Change to the extracted directory
verbose_echo "Changing to the extracted directory $HAPROXY_DIR..."
cd "$HAPROXY_DIR"

# Compile HAProxy with specific options
verbose_echo "Compiling HAProxy with specific options..."
make USE_NS=1 USE_TFO=1 USE_OPENSSL=1 USE_ZLIB=1 USE_PCRE=1 USE_SYSTEMD=1 USE_LIBCRYPT=1 USE_THREAD=1 USE_PROMEX=1 TARGET=linux-glibc

# Install HAProxy
verbose_echo "Installing HAProxy..."
sudo make TARGET=linux-glibc install-bin install-man

# Copy the executable to /usr/sbin
verbose_echo "Copying the HAProxy executable to /usr/sbin..."
sudo cp -f /usr/local/sbin/haproxy /usr/sbin/haproxy

# Change back to the working directory
verbose_echo "Changing back to the working directory $WORKDIR..."
cd "$WORKDIR"

# Remove the tar.gz file
verbose_echo "Removing the tar.gz file $HAPROXY_FILE..."
rm -f "$HAPROXY_FILE"

echo "HAProxy installation completed!"
