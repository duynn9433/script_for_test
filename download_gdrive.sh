#!/bin/bash

# Default values
default_fileid="1vK0MKE4sItU8DC0TzoqQS8nmFqXelZoX"
default_filename="apache-jmeter-5.6.2.zip"
default_confirm="t"

# Help message
help_message="
        Usage: ./download_script.sh [fileid] [filename] [confirm]

        Options:
                fileid      ID of the file to download (default: $default_fileid)
                filename    Name of the downloaded file (default: $default_filename)
                confirm     Confirmation flag (default: $default_confirm)
        "

# Check if no arguments provided or help option requested
if [ "$1" = "--help" ]
then
    echo "$help_message"
    exit 0
fi

# Check if arguments are provided, otherwise use defaults
fileid="${1:-$default_fileid}"
filename="${2:-$default_filename}"
confirm="${3:-$default_confirm}"

#Remove ihe file if it exists
#if [ -f "$filename" ]; then
#   rm -f "$filename"
#fi
curl -L "https://drive.usercontent.google.com/download?id=${fileid}&confirm=${confirm}" -o "${filename}"
