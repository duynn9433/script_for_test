#!/bin/bash
#################################################   Call   #####################################

echo StartTime: "$(date +'%Y-%m-%dT%H:%M:%S')"
for i in $(seq 1 10); do
    (
    sleep $((1 * i))
    echo StartTime"$i": "$(date +'%Y-%m-%dT%H:%M:%S')" > /home/vtn-duynn22/wrk/work-node/res_"$i".wrk
    wrk -t 1 -c 1 -d $((1 * (10 - i) + 300))s --timeout 6s "https://es1-p1-netcdn.tv360.vn/netcdn-live/304/output/304-audio_133600_eng=131600-video=6730000.m3u8?timestamp=1817589485&uid=test_12345&token=e543a4f37744f5e4b53f55df86d21a04"  -s /home/vtn-duynn22/Github/wrk/test_scripts/scripts2.lua >> /home/vtn-duynn22/wrk/work-node/res_"$i".wrk
    echo EndTime: "$(date +'%Y-%m-%dT%H:%M:%S')" >> /home/vtn-duynn22/wrk/work-node/res_"$i".wrk
    ) &
done
wait

echo EndTime: "$(date +'%Y-%m-%dT%H:%M:%S')"


#################################################   Merge   ####################################
output_file="$HOME/wrk/summary_report.wrk"
wrk_dir="$HOME/wrk/work-node"
max_attempts=4
wait_time=10

# Function to check if a file has completed execution
file_completed() {
    local file="$1"
    if grep -q "StartTime" "$file" && grep -q "EndTime" "$file"; then
        return 0
    else
        return 1
    fi
}

# Initialize variables to accumulate totals
title=""
total_thread=0
total_connection=0

total_requests=0
total_transfer=0
total_latency=0
total_latency_sd_numerator=0
total_latency_sd_denominator=0
total_requests_per_second=0
total_transfer_per_second_raw=0
total_transfer_per_second=0

p50_latency=0
p90_latency=0
p95_latency=0
p97_latency=0
p99_latency=0
p9999_latency=0

total_connect_errors=0
total_read_errors=0
total_write_errors=0
total_timeout_errors=0
total_status_errors=0

start_time=""
end_time=""
max_time=0
max_latency=0

# Remove the output file if it exists
rm -f "$output_file"
count_file=0
# Iterate over all .wrk files and extract relevant data
for file in "$wrk_dir"/res_*.wrk; do
    echo "Processing $file..."
    # Check if count_file is less than 1
    if [ "$count_file" -lt 1 ]; then
        # Search for "Running" in file
        title=$(grep "Running" "$file")
    fi

    # Increment count_file
    count_file=$((count_file + 1))
    ###########################    Wait for completion   ################################################
    # Wait for completion if the file hasn't finished executing
    attempts=0
    while ! file_completed "$file"; do
        attempts=$((attempts + 1))
        if [ "$attempts" -gt "$max_attempts" ]; then
            echo "File $file did not complete execution after $max_attempts attempts. Skipping."
            continue 2
        fi
        echo "File $file is not yet complete. Waiting for $wait_time seconds (Attempt $attempts/$max_attempts)..."
        sleep "$((wait_time * attempts))"
    done
    ###########################    Read File  #######################################################
    # Extract values from the current file
    thread=$(grep "threads" "$file" | awk '{print $1}')
    connection=$(grep "connections" "$file" | awk '{print $4}')

    requests=$((grep "TotalRequests:" "$file" || echo "0 0") | awk '{print $2}')
    time=$((grep "TotalTime:" "$file" || echo "0 0") | awk '{print $2}')
    transfer=$((grep "TotalTransfer:" "$file" || echo "0 0") | awk '{print $2}')
    latency=$((grep "Average:" "$file" || echo "0 0") | awk '{print $2}')
    maximum=$((grep "Maximum:" "$file" || echo "0 0") | awk '{print $2}')
    latency_sd=$((grep "StandardDeviation:" "$file" || echo "0 0" )| awk '{print $2}')
    requests_per_second=$((grep "RequestsPerSecond:" "$file" || echo "0 0") | awk '{print $2}')
    transfer_per_second_raw=$((grep "TransferPerSecondRaw:" "$file" || echo "0 0") | awk '{print $2}')
    transfer_per_second=$((grep "TransferPerSecond:" "$file" || echo "0 0") | awk '{print $2}')

    p50=$((grep "^50%\s\+[0-9.]\+ ms$" "$file" || echo "0 0") | awk '{print $2}')
    p90=$((grep "^90%\s\+[0-9.]\+ ms$" "$file" || echo "0 0") | awk '{print $2}')
    p95=$((grep "^95%\s\+[0-9.]\+ ms$" "$file" || echo "0 0") | awk '{print $2}')
    p97=$((grep "^97%\s\+[0-9.]\+ ms$" "$file" || echo "0 0") | awk '{print $2}')
    p99=$((grep "^99%\s\+[0-9.]\+ ms$" "$file" || echo "0 0") | awk '{print $2}')
    p9999=$((grep "^99.99%\s\+[0-9.]\+ ms$" "$file" || echo "0 0") | awk '{print $2}')

    connect_errors=$((grep "ErrorConnect:" "$file" || echo "0 0") | awk '{print $2}')
    read_errors=$((grep "ErrorRead:" "$file" || echo "0 0") | awk '{print $2}')
    write_errors=$((grep "ErrorWrite:" "$file" || echo "0 0") | awk '{print $2}')
    timeout_errors=$((grep "ErrorTimeout:" "$file" || echo "0 0") | awk '{print $2}')
    status_errors=$((grep "ErrorStatus:" "$file" || echo "0 0") | awk '{print $2}')
    
    file_start_time=$((grep "StartTime" "$file" || echo "0 0") | head -n 1 | awk '{print $2}')
    file_end_time=$((grep "EndTime" "$file" || echo "0 0") | head -n 1 | awk '{print $2}')

    ##########################   Update data   ########################################################
    # Update start_time and end_time
    if [ -z "$start_time" ] || [[ "$file_start_time" < "$start_time" ]]; then
        start_time=$file_start_time
    fi
    if [ -z "$end_time" ] || [[ "$file_end_time" > "$end_time" ]]; then
        end_time=$file_end_time
    fi

    # Calculate weights
    echo "Calculate weights"
    weighted_latency=$(echo "$requests * $latency" | bc)
    weighted_latency_sd=$(echo "($requests - 1) * $latency_sd^2" | bc)

    # Accumulate totals
    echo "Accumulate totals"
    total_thread=$(echo "$total_thread + $thread" | bc)
    total_connection=$(echo "$total_connection + $connection" | bc)
    total_requests=$(echo "$total_requests + $requests" | bc)
    max_time=$(echo "if($max_time > $time) $max_time else $time" | bc)
    total_transfer=$(echo "$total_transfer + $transfer" | bc)
    total_latency=$(echo "$total_latency + $weighted_latency" | bc)
    max_latency=$(echo "if($max_latency > $maximum) $max_latency else $maximum" | bc)
    # Std Dev
    total_latency_sd_numerator=$(echo "$total_latency_sd_numerator + $weighted_latency_sd" | bc)
    total_latency_sd_denominator=$(echo "$total_latency_sd_denominator + ($requests - 1)" | bc)

    p50_latency=$(echo "$p50_latency + $requests * $p50" | bc)
    p90_latency=$(echo "$p90_latency + $requests * $p90" | bc)
    p95_latency=$(echo "$p95_latency + $requests * $p95" | bc)
    p97_latency=$(echo "$p97_latency + $requests * $p97" | bc)
    p99_latency=$(echo "$p99_latency + $requests * $p99" | bc)
    p9999_latency=$(echo "$p9999_latency + $requests * $p9999" | bc)
    total_connect_errors=$(echo "$total_connect_errors + $connect_errors" | bc)
    total_read_errors=$(echo "$total_read_errors + $read_errors" | bc)
    total_write_errors=$(echo "$total_write_errors + $write_errors" | bc)
    total_timeout_errors=$(echo "$total_timeout_errors + $timeout_errors" | bc)
    total_status_errors=$(echo "$total_status_errors + $status_errors" | bc)

    total_requests_per_second=$(echo "$total_requests_per_second + $requests_per_second" | bc)
    total_transfer_per_second_raw=$(echo "$total_transfer_per_second_raw + $transfer_per_second_raw" | bc)
    total_transfer_per_second=$(echo "$total_transfer_per_second + $transfer_per_second" | bc)


    # Update maximum time and latency
    echo "Update maximum time and latency"
    
    
done

# Calculate averages
average_latency=$(echo "scale=3; $total_latency / $total_requests" | bc -l)

p50_latency=$(echo "scale=3; $p50_latency / $total_requests" | bc -l)
p90_latency=$(echo "scale=3; $p90_latency / $total_requests" | bc -l)
p95_latency=$(echo "scale=3; $p95_latency / $total_requests" | bc -l)
p97_latency=$(echo "scale=3; $p97_latency / $total_requests" | bc -l)
p99_latency=$(echo "scale=3; $p99_latency / $total_requests" | bc -l)
p9999_latency=$(echo "scale=3; $p9999_latency / $total_requests" | bc -l)

# Calculate pooled standard deviation
pooled_sd=$(echo "scale=3; sqrt($total_latency_sd_numerator / $total_latency_sd_denominator)" | bc -l)

# Calculate %err
total_err=$(echo "$total_connect_errors + $total_read_errors + $total_write_errors + $total_timeout_errors + $total_status_errors" | bc -l)
err_percent=$(echo "scale=3; ($total_err / ($total_requests + $total_err - $total_status_errors)) * 100" | bc -l)

# Write results to output file
cat << EOF > "$output_file"
$title
$total_thread threads and $total_connection connections
TotalFiles: $count_file
StartTime: $start_time
EndTime: $end_time
TotalRequests: $total_requests
TotalTime: $max_time s
TotalTransfer: $total_transfer Gb
AverageLatency: $average_latency ms
AverageLatencyStandardDeviation: $pooled_sd ms
RequestsPerSecond: $total_requests_per_second
TransferPerSecondRaw: $total_transfer_per_second_raw bytes
TransferPerSecond: $total_transfer_per_second Gb/s
MaximumLatency: $max_latency ms
Latency Distribution:
  50%: $p50_latency ms
  90%: $p90_latency ms
  95%: $p95_latency ms
  97%: $p97_latency ms
  99%: $p99_latency ms
  99.99%: $p9999_latency ms
ErrorConnect: $total_connect_errors
ErrorRead: $total_read_errors
ErrorWrite: $total_write_errors
ErrorTimeout: $total_timeout_errors
ErrorStatus: $total_status_errors
%Error: $err_percent %
EOF

echo "Summary report created at $output_file"
