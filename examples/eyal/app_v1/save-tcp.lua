local time_Save = tmr.now()
m = m + 1; mods[m] = "save/TCP"
time_dofile = time_dofile + (time_Save-start_dofile)
used ()

local function format_message()
	temp = temp or runCount%30
	time_First = time_First or 0
	time_Save = tmr.now() - time_Save

	local failSoft, failHard, failRead = 0, 0, 0
	if have_rtc_mem then
		failSoft = misc.rtc_mem_read_int(rtc_failSoft_address)
		failHard = misc.rtc_mem_read_int(rtc_failHard_address)
		failRead = misc.rtc_mem_read_int(rtc_failRead_address)
	end

	local vdd33
	if node.readvdd33 then
		vdd33 = node.readvdd33()-- new way
	else
		vdd33 = adc.readvdd33()	-- old way
	end

	return string.format (
"store %s %3d times=s%.3f,r%.3f,w%.3f,F%.3f,S%.3f,d%.3f,t%.3f stats=fs%d,fh%d,fr%d vdd=%.3f %.4f",
		clientID,
		runCount,
		time_start / 1000000,
		time_read / 1000000,
		time_wifi / 1000000,
		time_First / 1000000,
		time_Save / 1000000,
		time_dofile / 1000000,
		(tmr.now() - time_start) / 1000000,
		failSoft,
		failHard,
		failRead,
		vdd33 / 1000,
		temp)
end

if have_rtc_mem then
	misc.rtc_mem_write_int(rtc_runCount_address, runCount)
end

local conn = net.createConnection(net.TCP, 0)

conn:on("disconnection", function(conn)
	Log ("disconnected")

	doSleep()
end)

conn:on("sent", function(conn)
	Log ("sent")

	conn:close()
end)

conn:on("connection", function(conn)
	Log ("connected")

	local msg = format_message()
	Log ("send '%s'", msg)
	conn:send (msg)
end)

--Log("connecting to %s:%d", saveServer, savePort)
conn:connect(savePort, saveServer)
