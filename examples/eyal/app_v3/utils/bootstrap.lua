function wait () if not 5 == wifi.sta.status() or not wifi.sta.getip() then print(t().." need wifi") return end
  tmr.stop(1) print(t().." have wifi") conn = net.createConnection(net.TCP, 0)
  conn:on("connection", function(conn) conn:send("GET "..path.."/"..pgm.." HTTP/1.0\r\n".."Host: "..host.."\r\nConnection: close\r\nAccept: */*\r\n\r\n") end)
  conn:on("receive", function(conn, payload)
    if (found) then off = 0 else off = string.find(payload, "\r\n\r\n") if (off) then off = off+4 found = true end end
    if (off) then file.write(string.sub(payload, off)) file.flush() end end)
  conn:on("disconnection", function(conn) file.close() dofile(pgm) end)
  file.remove(pgm) file.open(pgm, "w+") ip, mask, host = wifi.sta.getip() found = false conn:connect(port,host)
end tmr.delay(2*1000000) port, path, pgm = 80, "/upload", "u.lc" t = tmr.now print(t().." get "..pgm) tmr.alarm(1, 100, 1, wait)
