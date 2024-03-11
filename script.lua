done = function(summary, latency, requests)
   io.write("------------------------------\n")
   print("TotalRequests: " .. summary.requests)
   -- time in second
   local time = summary.duration / 1000000 
   print("TotalTime: " .. string.format("%.3f", time) .. " s")
   
   -- Printing the total transfer in gigabits (Gb)
   local total_transfer_gb = summary.bytes * 8 / (1024^3)
   print("TotalTransfer: " .. string.format("%.3f", total_transfer_gb) .. " Gb")
   
   -- Printing the average (mean) latency in milliseconds
   print("Average: " .. string.format("%.3f", latency.mean / 1000) .. " ms")
   
   -- Printing the maximum latency in milliseconds
	 print("Maximum: " .. string.format("%.3f", latency.max / 1000) .. " ms")
	 
	 -- Printing the standard deviation of latency in milliseconds
   print("StandardDeviation: " .. string.format("%.3f", latency.stdev / 1000) .. " ms")
   
   print("Latency Distribution:")
   for _, p in pairs({ 50, 90, 97, 99.99 }) do
      local n = latency:percentile(p) / 1000  -- Convert from microseconds to milliseconds
      local msg = "%g%%    %.3f ms"
      print(msg:format(p, n))
   end
   
   -- Calculate percentage of all types of errors
   local total_requests = summary.requests
   local connect_errors = summary.errors.connect or 0
   local read_errors = summary.errors.read or 0
   local write_errors = summary.errors.write or 0
   local http_status_errors = summary.errors.status or 0
   local timeout_errors = summary.errors.timeout or 0

   local total_errors = connect_errors + read_errors + write_errors + http_status_errors + timeout_errors
   local error_percentage = (total_errors / total_requests) * 100
   print("%Error: " .. string.format("%.3f", error_percentage) .. " %")
   
   -- Calculate requests per second
   local total_requests = summary.requests
   local duration_seconds = summary.duration / 1000000 -- converting microseconds to seconds
   local rps = total_requests / duration_seconds
   print("RequestsPerSecond: " .. string.format("%.3f", rps))

   -- Calculate transfer per second
   local total_bytes = summary.bytes
   local tps = total_bytes / duration_seconds
   print("TransferPerSecondRaw: " .. string.format("%.3f", tps) .. " bytes")
   
   -- Calculate transfer per second in GB/s
   local total_bytes = summary.bytes
   local duration_seconds = summary.duration / 1000000 -- converting microseconds to seconds
   local tps_gb = total_bytes * 8 / (duration_seconds * 1024 * 1024 * 1024) -- converting bytes to gigabytes
   print("TransferPerSecond: " .. string.format("%.3f", tps_gb) .. " Gb/s")
end