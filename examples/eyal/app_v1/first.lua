time_First = tmr.now()
m = m + 1; mods[m] = "first"
time_dofile = time_dofile + (time_First-start_dofile)
used ()

local conn = net.createConnection(net.TCP, 0)

conn:on("disconnection", function(conn, data)
	Log ("disconnected")

	if not runCount then runCount = 1 end

	time_First = tmr.now() - time_First
	do_file ("save-"..save_proto)
end)

conn:on("receive", function(conn, data)
	Log ("received '%s'", data)

	runCount = data + 1

	tmr.wdclr()
	conn:close()
end)

conn:on("sent", function(conn)
	Log ("sent")
end)

conn:on("connection", function(conn)
	Log ("connected")

	tmr.wdclr()
	conn:send (string.format("last/%s", clientID))	-- request last runCount
end)

tmr.wdclr()
conn:connect(savePort, saveServer)
