function delay()
    return 3000
end

done = function(summary, latency, requests)
   io.write("------------------------------\n")
   for _, p in pairs({ 50, 90, 97, 99.99 }) do
      n = latency:percentile(p)
      local msg = "%g%%    %d"
      print(msg:format(p, n))
   end
end
