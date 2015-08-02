function Log (...) mLog ("save", unpack(arg)) end
local time_Save = done_file (tmr.now())
used ()

local function format_message()
	local failSoft, failHard, failRead, timeLast, timeTotal
		= 0, 0, 0, 0, 0
	if have_rtc_mem then
		failSoft = misc.rtc_mem_read_int(rtc_failSoft_address)
		failHard = misc.rtc_mem_read_int(rtc_failHard_address)
		failRead = misc.rtc_mem_read_int(rtc_failRead_address)
		timeLast = misc.rtc_mem_read_int(rtc_lastTime_address)
		timeTotal = misc.rtc_mem_read_int(rtc_totalTime_address)
	end

	local times = ""
	if send_times then
		time_Save = tmr.now() - time_Save
		times = string.format (
" times=L%.3f,T%d,s%.3f,u%.3f,r%.3f,w%.3f,F%.3f,S%.3f,d%.3f,t%.3f",
			timeLast / 1000,
			timeTotal / 1000,
			time_start / 1000000,
			time_setup / 1000000,
			time_read / 1000000,
			time_wifi / 1000000,
			time_First / 1000000,
			time_Save / 1000000,
			time_dofile / 1000000,
			(tmr.now() - time_start) / 1000000)
	end

	local stats = ""
	if send_stats then
		stats = string.format (" stats=fs%d,fh%d,fr%d",
			failSoft,
			failHard,
			failRead)
		if send_mem then
			mem_used = mem_used or 0
			mem_heap = mem_heap or 0
			stats = string.format ("%s,mu%d,mh%d",
				stats,
				mem_used,
				mem_heap)
		end
	end

	local vbat = 0
	if adc_factor then
		vbat = adc.read(0)*adc_factor
	end

	local vdd33 = nil
	if node.readvdd33 then
		vdd33 = node.readvdd33()	-- new way
	else
		vdd33 = adc.readvdd33()		-- old way
	end
	if not vdd33 then vdd33 = 0 end

	local tCs = ""
	local tSep = ""
	for n = 1,#ow_addr do
		tCs = string.format ("%s%s%.4f", tCs, tSep,
			(temp[n] or 0))
		tSep = ","
	end

	return string.format (
		"store %s %3d%s%s adc=%.3f vdd=%.3f %s",
		clientID,
		runCount,
		times,
		stats,
		vbat / 1000,
		vdd33 / 1000,
		tCs)
end

if have_rtc_mem then
	misc.rtc_mem_write_int(rtc_runCount_address, runCount)
end

local msg = format_message()
format_message = nil

if not do_Save then
	print_log = true
	Log (msg)
	msg = nil
	doSleep()
elseif "udp" == save_proto then
	local conn = net.createConnection(net.UDP, 0)

	conn:on("sent", function(conn)
		Log ("sent")
		msg = nil

		conn:close()

		doSleep()
	end)

	Log("connecting to %s:%d", saveServer, savePort)
	conn:connect(savePort, saveServer)

	Log ("send '%s'", msg)
	conn:send (msg)
--[[else
	local conn = net.createConnection(net.TCP, 0)

	conn:on("disconnection", function(conn)
		Log ("disconnected")

		doSleep()
	end)

	conn:on("sent", function(conn)
		Log ("sent")
		msg = nil

		conn:close()
	end)

	conn:on("connection", function(conn)
		Log ("connected")

		Log ("send '%s'", msg)
		conn:send (msg)
	end)

	Log("connecting to %s:%d", saveServer, savePort)
	conn:connect(savePort, saveServer)
--]]end
