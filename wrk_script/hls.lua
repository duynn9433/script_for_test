local logFile = io.open("debug.log", "a")
local resultFile = io.open("result.log", "a")
-- https://es1-p1-netcdn.tv360.vn/netcdn-live/304/output/304-audio_133600_eng=131600-video=6730000.m3u8?timestamp=1817589485&uid=test_12345&token=e543a4f37744f5e4b53f55df86d21a04
local m3u8Url = "/netcdn-live/192/output/192-audio_142800_eng=140800-video=5154400.m3u8"
local delay_time_ms = 4000

function log(message)
    logFile:write(message .. "\n")
    logFile:flush()
end

function result_log(message)
    resultFile:write(message .. "\n")
    resultFile:flush()
end

-- log("Script loaded")

function is_valid_url(url)
    local pattern = "^https?://[%w-_%.%?%.:/%+=&]+$"
    return url:match(pattern) ~= nil
end

function get_last_valid_url(body)
    local lines = {}
    for line in body:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    for i = #lines, 1, -1 do
        local line = lines[i]
        if not line:match("^#") and is_valid_url(line) then
            return line
        end
    end

    return nil
end

function is_m3u8(headers)
    for key, value in pairs(headers) do
        if key:lower() == "content-type" and value:lower() == "application/vnd.apple.mpegurl" then
            return true
        elseif key:lower() == "content-type" and value:lower() == "application/x-mpegurl" then
            return true
        elseif key:lower() == "content-type" and value:lower() == "application/m3u8" then
            return true
        end
    end
    return false
end

function delay()
    return delay_time_ms 
end

function init(args)
    currChunkUrl = ""
    lastChunkUrl = ""
    r = {}
end
 
function request()
    -- log("Curr Chunk URL: " .. currChunkUrl)
    if currChunkUrl < lastChunkUrl then 
        currChunkUrl = lastChunkUrl
        -- log("Chunk URL: " .. currChunkUrl)
    end
    if currChunkUrl ~= "" then 
        r[1] = wrk.format(nil, currChunkUrl)
        r[2] = wrk.format(nil, m3u8Url)
    else
        r[1] = wrk.format(nil, m3u8Url)
    end
    -- r[1] = wrk.format(nil, m3u8Url)
    req = table.concat(r)
    -- log("request table:" .. req)
    return req
end

response = function(status, headers, body)
    if status == 200 and is_m3u8(headers) then
        -- log("Response is an M3U8 file.")
        -- log("Response received with body: " .. body)
        local last_valid_url = get_last_valid_url(body)
        if last_valid_url then
            -- log("Last valid URL: " .. last_valid_url)
            lastChunkUrl = last_valid_url
        else
            -- log("No valid URL found")
        end
    elseif status ~= 200 then
        log(status)
    else
        -- log("Response is not an M3U8 file. Skipping body check.")
    end
end

done = function(summary, latency, requests)
    local total_request = summary.requests
    io.write("------------------------------\n")
    print("TotalRequests: " .. total_request)
    -- time in second
    local time = summary.duration / 1000000 
    print("TotalTime: " .. string.format("%.3f", time) .. " s")
    
    -- Printing the total transfer in gigabits (Gb)
    local total_transfer_gb = summary.bytes * 8 / (1024^3)
    print("TotalTransfer: " .. string.format("%.3f", total_transfer_gb) .. " Gb")
    
    -- Printing the average (mean) latency in milliseconds
    local avg_latency = latency.mean / 1000
    print("Average: " .. string.format("%.3f", avg_latency) .. " ms")
    
    -- Printing the maximum latency in milliseconds
    local max_latency = latency.max / 1000
    print("Maximum: " .. string.format("%.3f", max_latency) .. " ms")
      
    -- Printing the standard deviation of latency in milliseconds
    local std_dev_latency = latency.stdev / 1000
    print("StandardDeviation: " .. string.format("%.3f", std_dev_latency) .. " ms")
    
    print("Latency Distribution:")
    local l50 = latency:percentile(50) and latency:percentile(50) / 1000 or 0
    local l90 = latency:percentile(90) and latency:percentile(90) / 1000 or 0
    local l95 = latency:percentile(95) and latency:percentile(95) / 1000 or 0
    local l97 = latency:percentile(97) and latency:percentile(97) / 1000 or 0
    local l99 = latency:percentile(99) and latency:percentile(99) / 1000 or 0
    local l9999 = latency:percentile(99.99) and latency:percentile(99.99) / 1000 or 0
    for _, p in pairs({ 50, 90, 95, 97, 99, 99.99 }) do
       local n = latency:percentile(p) / 1000  -- Convert from microseconds to milliseconds
       local msg = "%g%%    %.3f ms"
       print(msg:format(p, n))
    end
    
    -- Calculate the percentage of all types of errors
    local connect_errors = summary.errors.connect or 0
    print("ErrorConnect: " .. connect_errors)
    local read_errors = summary.errors.read or 0
    print("ErrorRead: " .. read_errors)
    local write_errors = summary.errors.write or 0
    print("ErrorWrite: " .. write_errors)
    local http_status_errors = summary.errors.status or 0
    print("ErrorStatus: " .. http_status_errors)
    local timeout_errors = summary.errors.timeout or 0
    print("ErrorTimeout: " .. timeout_errors)
 
    local total_errors = connect_errors + read_errors + write_errors + http_status_errors + timeout_errors
    local total_request_with_err = total_request + connect_errors + read_errors + write_errors + timeout_errors 	
    local error_percentage = (total_errors / total_request_with_err) * 100
    print("%Error: " .. string.format("%.3f", error_percentage) .. " %")
    
    -- Calculate requests per second
    local duration_seconds = summary.duration / 1000000 -- converting microseconds to seconds
    local rps = total_request / duration_seconds
    print("RequestsPerSecond: " .. string.format("%.3f", rps))
 
    -- Calculate transfer per second
    local total_bytes = summary.bytes
    local tps = total_bytes / duration_seconds
    print("TransferPerSecondRaw: " .. string.format("%.3f", tps) .. " bytes")
    
    -- Calculate transfer per second in GB/s
    local tps_gb = total_bytes * 8 / (duration_seconds * 1024 * 1024 * 1024) -- converting bytes to gigabytes
    print("TransferPerSecond: " .. string.format("%.3f", tps_gb) .. " Gb/s")

    --print to csv 
    local currentTime = os.date("%Y-%m-%d %H:%M:%S")
    result_log(currentTime)
    result_log("TotalRequests,TotalTime,TotalTransfer,Average,Maximum,StandardDeviation,P50,P90,P95,P97,P99,P9999,ErrorConnect,ErrorRead,ErrorWrite,ErrorStatus,ErrorTimeout,ErrorPercentage,RequestsPerSecond,TransferPerSecond,TransferPerSecondRAW,")
    result_log(string.format("%d,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%d,%d,%d,%d,%d,%.3f,%.3f,%.3f,%.3f,\n",
    total_request, time, total_transfer_gb, avg_latency, max_latency, std_dev_latency,
    l50, l90, l95, l97, l99, l9999,
    connect_errors, read_errors, write_errors, http_status_errors, timeout_errors, error_percentage, rps, tps_gb, tps))
 end
