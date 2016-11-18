function Log (...) mLog ("save", unpack(arg)) end
local tmr = tmr
local time_Save = done_file (tmr.now())
used ()
out_bleep()

local function format_message()
	local failSoft, failHard, failRead, timeLast, timeTotal
		= 0, 0, 0, 0, 0
	if have_rtc_mem then
		failSoft  = rtcmem.read32(rtca_failSoft)	-- count
		failHard  = rtcmem.read32(rtca_failHard)	-- count
		failRead  = rtcmem.read32(rtca_failRead)	-- count
		timeLast  = rtcmem.read32(rtca_lastTime)	-- us
		timeTotal = rtcmem.read32(rtca_totalTime)	-- ms
	end

	local times = ""
	if send_times then
		time_Save = tmr.now() - time_Save
		times = 
(" times=L%.3f,T%d,s%.3f,u%.3f,r%.3f,w%.3f,F%.3f,S%.3f,d%.3f,t%.3f"):format(
			timeLast / 1000000,
			timeTotal / 1000,
			time_start / 1000000,
			time_setup / 1000000,
			time_read / 1000000,
			time_wifi / 1000000,
			time_First / 1000000,
			time_Save / 1000000,
			time_dofile / 1000000,
			(tmr.now() - time_start) / 1000000)
		if nil ~= rtc_start_s then
			times = ("%s,R%d.%06d"):format(
				times,
				rtc_start_s, rtc_start_u)
		end
	end

	local stats = ""
	if send_stats then
		stats = (" stats=fs%d,fh%d,fr%d"):format(
			failSoft,
			failHard,
			failRead)
		if send_mem then
			local mu = mem_used or 0
			local mh = mem_heap or 0
			stats = ("%s,mu%d,mh%d"):format(
				stats,
				mu,
				mh)
		end
	end

	local radio = ""
	if send_radio then
		radio = (" radio=s%d"):format(
			-wifi.sta.getrssi())
	end

	if adc_factor then	-- no vdd with adc anymore
		vbat = adc.read(0)*adc_factor
		vdd33 = 3300			-- dummy
	else
		vbat = 0			-- dummy
		vdd33 = adc.readvdd33()*vdd_factor
	end

	local noTemp = 0			-- or 85?
	local tCs
	if 0 == #temp then
		tCs = ("%.4f"):format(noTemp)
	else
		tCs = ""
		local tSep = ""
		for n = 1,#temp do
			tCs = ("%s%s%.4f"):format(tCs, tSep, (temp[n] or noTemp))
			tSep = ","
		end
	end

	return ("store %s %3d%s%s%s adc=%.3f vdd=%.3f %s"):format(
		clientID,
		runCount,
		times,
		stats,
		radio,
		vbat / 1000,
		vdd33 / 1000,
		tCs)
end

if have_rtc_mem then
	rtcmem.write32(rtca_runCount, runCount)
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
		grace_time = tmr.now() + udp_grace_ms*1000
		Log ("sent")
		msg = nil

		conn:close()
		doSleep()
	end)

	Log("connecting to %s:%d", saveServer, savePort)
	conn:connect(savePort, saveServer)

	Log ("send '%s'", msg)
	conn:send (msg)
--[[else	-- tcp
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
