#!/bin/bash
#################################### How to use ####################################
# Log line example:
# 1716938796.059 386 117.0.16.85 es2-p2-netcdn.tv360.vn "Go-http-client/1.1" TCP_CF_HIT 200 2660051 GET https://es2-p2-netcdn.tv360.vn/netcdn-live/192/output/192-audio_142800_eng=140800-video=5154400-429234698.ts video/MP2T -1 "-"
# Usage:
#     Script_name.sh start_time end_time log_file print_err_log(true/false) 
# Example:
#     [root@es2-p2-netcdn u01]# bash log_analysis.sh 1716937200 1716939000 squid.log.5 true -v
#     Processing log file...
#     Total number of elements in arr: 6908485
#     P50: 1
#     P99: 50
#     Max: 386
#     Avg: 2.02983
#     Error log count (status code != 200): 0
#     Max response time log line: 1716938796.059 386 117.0.16.85 es2-p2-netcdn.tv360.vn "Go-http-client/1.1" TCP_CF_HIT 200 2660051 GET https://es2-p2-netcdn.tv360.vn/netcdn-live/192/output/192-audio_142800_eng=140800-video=5154400-429234698.ts video/MP2T -1 "-"
#     Script execution completed.
#
####################################################################################
# Check if the correct number of arguments are provided
if [ "$#" -lt 3 ] || [ "$#" -gt 5 ]; then
    echo "Usage: $0 <start_time> <end_time> <file_path> [print_error_logs] [-v]"
    exit 1
fi

# Assign the input arguments to variables
start_time=$1
end_time=$2
file_path=$3
print_error_logs=${4:-false}
verbose=${5:-false}

if [ "$verbose" == "-v" ]; then
    verbose=true
else
    verbose=false
fi

# Validate that the file exists
if [ ! -f "$file_path" ]; then
    echo "Error: File '$file_path' not found."
    exit 1
fi

# Verbose mode
if $verbose; then echo "Processing log file..."; fi

# Use awk to filter logs, count errors, collect response times, find the max log line, and calculate the average response time
awk -v start="$start_time" -v end="$end_time" -v print_errors="$print_error_logs" -v verbose="$verbose" '
BEGIN {
    error_count = 0;
    max_response_time = -1;
    max_log_line = "";
    total_response_time = 0;
    count = 0;
}
{
    timestamp = $1;
    response_time = $2;
    client_ip = $3;
    status_code = $7;

    if (timestamp >= start && timestamp <= end && (client_ip == "117.0.16.85" || client_ip == "117.0.16.53")) {
        if (status_code != 200) {
            error_count++;
            if (print_errors == "true") {
                print $0;
            }
        }
        times[count] = response_time;
        total_response_time += response_time;
        count++;

        if (response_time > max_response_time) {
            max_response_time = response_time;
            max_log_line = $0;
        }
    }
}
END {
    if (count > 0) {
        n = asort(times);
        p97 = times[int(n * 0.97)];
        p99 = times[int(n * 0.99)];
        p9999 = times[int(n * 0.9999)];
        max = times[n];
        avg = total_response_time / count;
    } else {
        p97 = "N/A";
        p99 = "N/A";
        p9999 = "N/A";
        max = "N/A";
        avg = "N/A";
    }

    print "Total number of elements in arr:", count;
    print "P97:", p97;
    print "P99:", p99;
    print "P9999:", p9999;
    print "Max:", max;
    print "Avg:", avg;
    print "Error log count (status code != 200):", error_count;
    print "Max response time log line:", max_log_line;

    if (verbose == "true") {
        print "Script execution completed.";
    }
}
' "$file_path"
