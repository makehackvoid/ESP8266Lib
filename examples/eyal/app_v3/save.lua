local tmr = tmr
local time_Save = done_file (tmr.now())
local mLog = mLog
local function Log (...) if print_log then mLog ("save", unpack(arg)) end end
local function Trace(n) mTrace(7, n) end Trace (0)
used ()
out_bleep()

local function format_message()
	local failSoft, failHard, failRead, timeLast, timeTotal, timeLeft
		= 0, 0, 0, 0, 0, 0
	if have_rtc_mem then
		failSoft  = rtcmem.read32(rtca_failSoft)	-- count
		failHard  = rtcmem.read32(rtca_failHard)	-- count
		failRead  = rtcmem.read32(rtca_failRead)	-- count
		timeLast  = rtcmem.read32(rtca_lastTime)	-- us
		timeTotal = rtcmem.read32(rtca_totalTime)	-- ms
		timeLeft  = rtcmem.read32(rtca_timeLeft)	-- us
	end

	local times = ""
	if send_times then
		time_Save = tmr.now() - time_Save
		times = 
(" times=L%.3f,l%.3f,T%d,s%.3f,u%.3f,r%.3f,w%.3f,F%.3f,S%.3f,d%.3f,t%.3f"):format(
			timeLast / 1000000,	-- from prev cycle
			timeLeft / 1000000,	-- from prev cycle
			timeTotal / 1000,	-- from prev cycle
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
		local reasons = ""
		if send_reason then
--[[
struct rst_info* ri = system_get_rst_info();
struct rst_info {
	uint32 reason; // enum rst_reason
	uint32 exccause;
	uint32 epc1;  // the address that error occurred
	uint32 epc2;
	uint32 epc3;
	uint32 excvaddr;
	uint32 depc;
};
enum rst_reason {
	REASON_DEFAULT_RST      = 0, // normal startup by power on
	REASON_WDT_RST	        = 1, // hardware watch dog reset 
	// exception reset, GPIO status won't change 
	REASON_EXCEPTION_RST    = 2, 
	// software watch dog reset, GPIO status won't change 
	REASON_SOFT_WDT_RST     = 3, 
	// software restart, system_restart , GPIO status won't change
	REASON_SOFT_RESTART     = 4, 
	REASON_DEEP_SLEEP_AWAKE = 5, // wake up from deep-sleep 
	REASON_EXT_SYS_RST      = 6, // external system reset
};
code = rtc_get_reset_reason();
reason = ri.reason;
--]]
			local code, reason = node.bootreason()
			times = ("%s,b%d/%d"):format(
				times,
				code, reason)
		end
	end

	local stats = ""
	if send_stats then
		stats = (" stats=fs%d,fh%d,fr%d,t%u"):format(
			failSoft,
			failHard,
			failRead,
			(last_trace or 99999999))
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

	if not weather then weather = "" end

	return ("store %s %3d%s%s%s%s adc=%.3f vdd=%.3f %s"):format(
		clientID,
		runCount,
		times,
		stats,
		radio,
		weather,
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
