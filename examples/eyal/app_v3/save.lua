local tmr = tmr
local time_Save = done_file (tmr.now())
local mLog = mLog
local sta = wifi.sta
local function Log (...) if print_log then mLog ("save", unpack(arg)) end end
local function Trace(n, new) mTrace(7, n, new) end Trace (0)
used ()
out_bleep()

local function format_message()
	local failSoft, failHard, failRead, timeLast, timeTotal, timeLeft
		= 0, 0, 0, 0, 0, 0
	if have_rtc_mem then
		failSoft  = rtcmem.read32(rtca_failSoft)	-- count
		failHard  = rtcmem.read32(rtca_failHard)	-- count
		failRead  = rtcmem.read32(rtca_failRead)	-- count
		-- data from prev cycle:
		timeLast  = rtcmem.read32(rtca_lastTime)	-- us
		timeTotal = rtcmem.read32(rtca_totalTime)	-- ms
		timeLeft  = rtcmem.read32(rtca_timeLeft)	-- us
		-- also last_trace
	end

	local command = 'store '
	if "mqtt" == save_proto then command = '' end

	local times = ""
	if send_times then
		time_Save = tmr.now() - time_Save
		times = 
(" times=s%.3f,u%.3f,r%.3f,w%.3f,F%.3f,S%.3f,d%.3f,t%.3f prev=L%.3f,l%.3f,T%d,t%x"):format(
			time_start / 1000000,
			time_setup / 1000000,
			time_read / 1000000,
			time_wifi / 1000000,
			time_First / 1000000,
			time_Save / 1000000,
			time_dofile / 1000000,
			(tmr.now() - time_start) / 1000000,
			-- prev=
			timeLast / 1000000,	-- from prev cycle
			timeLeft / 1000000,	-- from prev cycle
			timeTotal / 1000,	-- from prev cycle
			(last_trace or 0xffffffff))
		if nil ~= rtc_start_s then
			times = ("%s,R%d.%06d"):format(
				times,
				rtc_start_s, rtc_start_u)
		end
	end

	local stats = ""
	if send_stats then
		local reasons = ""
		if send_reason then
--[[
code:
    1 power-on
    2 reset (software?)
    3 hardware reset via reset pin
    4 WDT reset (watchdog timeout)

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
			reasons = (",c%d,r%d"):format(
				code, reason)
		end

		local mems = ""
		if send_mem then
			local mu = mem_used or 0
			local mh = mem_heap or 0
			mems = (",mu%d,mh%d"):format(
				mu,
				mh)
		end

		stats = (" stats=fs%d,fh%d,fr%d%s%s"):format(
			failSoft,
			failHard,
			failRead,
			reasons,
			mems)
	end

	local radio = ""
	if send_radio then
		radio = (" radio=s%d"):format(
			-sta.getrssi())
	end

	if not weather then weather = "" end

	if adc_factor then	-- cannot read vdd with adc anymore
		vbat = adc.read(0)*adc_factor
		vdd33 = rtcmem.read32(rtca_vddLastRead)
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

	return ("%s%s %3d%s%s%s%s adc=%.3f vdd=%.3f %s%s"):format(
		command,
		clientID,
		runCount,
		times,
		stats,
		radio,
		weather,
		vbat / 1000,
		vdd33 / 1000,
		tCs,
		save_eom)
end

if have_rtc_mem then
	rtcmem.write32(rtca_runCount, runCount)
end

message = format_message()
format_message = nil

if not do_Save then
	Trace(1)
	print_log = true
	Log (message)
	message = nil
	doSleep()
elseif "udp" == save_proto then
	Trace(2)
	do_file("save-udp")
elseif "tcp" == save_proto then
	Trace(3)
	do_file("save-tcp")
elseif "mqtt" == save_proto then
	Trace(4)
	do_file("save-mqtt")
else
	Trace(5)
	pgm = ("save-%s"):format(save_proto)
	if not pcall (function() do_file(pgm, true) end) then
		Trace(6)
		Log ("missing or failing '%s'", pgm)
		Log ("message='%s'", message)
		message = nil
		doSleep()
	end
end
