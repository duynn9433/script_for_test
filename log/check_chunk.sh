#!/bin/bash

# Base URLs with different IP addresses
BASE_URLS=("http://172.24.16.138/bpk-tv/155/output/"
           "http://172.24.16.139/bpk-tv/155/output/"
           "http://172.24.16.140/bpk-tv/155/output/"
           "http://172.24.16.234/bpk-tv/155/output/"
           "http://172.24.16.235/bpk-tv/155/output/"
           "http://172.24.16.236/bpk-tv/155/output/")

# File naming pattern
FILE_PATTERN="155-audio_142800_eng=140800-video=5154400"

# Log file for errors
ERROR_LOG="error.log"

# Log count
LOG_COUNT=0

# Error count
ERR_COUNT=0

# ANSI color codes
GREEN='\033[0;32m'
NC='\033[0m'  # No Color

# Function to check if the chunk is OK
check_chunk() {
  local file=$1
  local base_url=$2
  #local output=$(ffprobe -v error -show_entries stream=index,codec_name,codec_type,channels,width,height:format=duration -of default=noprint_wrappers=1:nokey=1 $file 2>&1)
  local output=$(ffprobe -v error -show_entries stream=index,codec_name,codec_type,channels,width,height:format=duration -of default=noprint_wrappers=1:nokey=1 -of default=noprint_wrappers=1 $file 2>&1)
  # Extract IP address from base URL
  local ip=$(echo $base_url | awk -F'/' '{print $3}')
  
  # Increment log count
  ((LOG_COUNT++))
  
  # Print log count
  echo "Log count: $LOG_COUNT"

  # Print debug header
  echo "--------------------  ${GREEN}${file}${NC} ---------------"
  
  # Print the full output for debugging
  echo "$output"

  # Check for "channels=0" in the output
  if echo "$output" | grep -q "channels=0"; then
    echo -e "${RED}${file}${NC} FAIL from IP ${ip} (0 channels in audio)" | tee -a $ERROR_LOG
    ((ERR_COUNT++))
  else
    echo -e "${GREEN}${file}${NC} OK from IP ${ip}"
    rm $file
  fi

  # Print error count
  echo "Error count: $ERR_COUNT"
}

# Start and end counters as parameters
start_counter=$1
end_counter=$2

# Check if the start and end counters are provided
if [ -z "$start_counter" ] || [ -z "$end_counter" ]; then
  echo "Usage: $0 <start_counter> <end_counter>"
  exit 1
fi

# Loop through the chunk files
for (( counter=start_counter; counter<=end_counter; counter++ )); do
  for base_url in "${BASE_URLS[@]}"; do
    (
      file="${FILE_PATTERN}-${counter}.ts"
      url="${base_url}${file}"

      # Download the file using the base URL
      wget $url -O $file

      # Check the downloaded file
      check_chunk $file $base_url

      # Add a sleep to prevent spamming the server
      sleep 1
    ) &
    ((counter++))
    if (( counter > end_counter )); then
      break
    fi
  done
  wait
done

# Print total error count at the end
echo "Total errors encountered: $ERR_COUNT"
