#!/bin/bash
#### input is http://127.0.0.1/<media_playlist_path>?begin=<start_time>&end=<end_time>####
# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <http://127.0.0.1/<media_playlist_path>?begin=<start_time>&end=<end_time>>"
  exit 1
fi

# Extract the base URL
input_url=$1
base_url=$(echo "$input_url" | sed 's|\?.*||' | sed 's|.m3u8$||')

# Extract the startTime and endTime from the query parameters
startTime=$(echo "$input_url" | grep -oP '(?<=begin=)\d+')
endTime=$(echo "$input_url" | grep -oP '(?<=end=)\d+')
echo "Time: $startTime -> $endTime"

# Function to print status code with color
print_status_code() {
  local status_code=$1
  if [[ $status_code =~ 2[0-9]{2} ]]; then
    echo -e "\e[32m$status_code\e[0m"  # Green for 2xx
  elif [[ $status_code =~ 4[0-9]{2} ]]; then
    echo -e "\e[31m$status_code\e[0m"  # Red for 4xx
  else
    echo "$status_code"  # Default color for other status codes
  fi
}

#### Purge manifest ######
# Loop from start to end
for ((i=startTime; i<=endTime; i++)); do
  # Make the curl request and get the status code
  status_code=$(curl -o /dev/null -s -w "%{http_code}\n" -X PURGE "${base_url}.m3u8?wm=${i}")
  echo -n "Manifest $i - "
  print_status_code "$status_code"
done

#### Get manifest and get min&max Chunk ####
M3U8_CONTENT=$(curl -s "$input_url")
startChunk=$(echo "$M3U8_CONTENT" | grep -oP 'https://[^\s]+\.ts' | head -n 1 | sed 's/.*-\(.*\)\.ts/\1/')
lastChunk=$(echo "$M3U8_CONTENT" | grep -oP 'https://[^\s]+\.ts' | tail -n 1 | sed 's/.*-\(.*\)\.ts/\1/')

#### Purge chunk #########
for ((i=startChunk; i<=lastChunk; i++)); do
  # Make the curl request and get the status code
  status_code=$(curl -o /dev/null -s -w "%{http_code}\n" -X PURGE "${base_url}-${i}.ts")
  echo -n "Chunk $i - "
  print_status_code "$status_code"
done
