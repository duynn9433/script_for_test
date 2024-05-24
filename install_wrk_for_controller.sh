#!/bin/bash

# Function to print messages when verbose mode is enabled
verbose_echo() {
    if [ "$VERBOSE" = true ]; then
        echo "$@"
    fi
}

# Function to display help message
show_help() {
    echo "Usage: $0 [-v] [-h]"
    echo ""
    echo "Options:"
    echo "  -v      Enable verbose mode."
    echo "  -h      Show this help message."
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

# Step 1: Create the wrk directory if it doesn't exist and grant permissions to vt_admin:vt_admin
wrk_dir="/home/vt_admin/wrk"
if [ ! -d "$wrk_dir" ]; then
    verbose_echo "Creating directory $wrk_dir"
    sudo mkdir -p "$wrk_dir"
    sudo chown -R vt_admin:vt_admin "$wrk_dir"
    sudo chmod 744 "$wrk_dir"
fi

# Step 2: Check and install wrk if necessary
if ! command -v wrk &> /dev/null; then
    verbose_echo "Installing dependencies"
    sudo dnf -y install make automake gcc openssl-devel git

    verbose_echo "Clone the wrk repository"
    git clone https://github.com/wg/wrk.git
    cd wrk || exit 1

    verbose_echo "Build wrk"
    make

    verbose_echo "Move the wrk binary to a directory in PATH"
    sudo mv wrk /usr/local/bin/

    verbose_echo "Clean up"
    cd ..
    sudo rm -rf wrk
fi

# Step 3: Set permissions to run wrk for vt_admin:vt_admin
sudo chown vt_admin:vt_admin /usr/local/bin/wrk
sudo chmod +x /usr/local/bin/wrk

echo "Done!"
