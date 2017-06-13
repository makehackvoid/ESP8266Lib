local mLog = mLog
local function Log (...) if print_log then mLog ("main", unpack(arg)) end end
time_setup = done_file (tmr.now())
local function Trace(n, new) mTrace(3, n, new) end Trace (0, true)
used ()
out_bleep()

local sta = wifi.sta
local rtcmem = rtcmem

-- address in RTC of counters and value of magic
local function setup_rtcmem()
	have_rtc_mem = nil ~= rtcmem
	if not have_rtc_mem then
		newRun = true	-- always fetch runCount from server
		return true
	end
	rtc_magic        = rtc_magic        or 0x6adadad0	-- keep below 0x80000000
	rtca_magic       = rtca_magic       or 127		-- last slot
	rtca_runCount    = rtca_runCount    or (rtca_magic - 1)
	rtca_failSoft    = rtca_failSoft    or (rtca_magic - 2)
	rtca_failHard    = rtca_failHard    or (rtca_magic - 3)
	rtca_failRead    = rtca_failRead    or (rtca_magic - 4)
	rtca_lastTime    = rtca_lastTime    or (rtca_magic - 5)
	rtca_totalTime   = rtca_totalTime   or (rtca_magic - 6)
	rtca_timeLeft    = rtca_timeLeft    or (rtca_magic - 7)
	rtca_tracePointH = rtca_tracePointH or (rtca_magic - 8)
	rtca_tracePointL = rtca_tracePointL or (rtca_magic - 9)
	rtca_vddNextTime = rtca_vddNextTime or (rtca_magic - 10)	-- ms to next vdd read
	rtca_vddLastRead = rtca_vddLastRead or (rtca_magic - 11)
	rtca_vddAdjTime  = rtca_vddAdjTime  or (rtca_magic - 12)

	newRun = rtc_magic ~= rtcmem.read32(rtca_magic)
	if newRun then
		rtcmem.write32(rtca_runCount, 0)
		rtcmem.write32(rtca_failSoft, 0)
		rtcmem.write32(rtca_failHard, 0)
		rtcmem.write32(rtca_failRead, 0)
		rtcmem.write32(rtca_lastTime, 0)
		rtcmem.write32(rtca_totalTime, 0)
		rtcmem.write32(rtca_timeLeft, 0)
		rtcmem.write32(rtca_tracePointH, 0xffffffff)
		rtcmem.write32(rtca_tracePointL, 0xffffffff)
		last_trace_h, last_trace_l = 0xffffffff, 0xffffffff
		rtcmem.write32(rtca_vddNextTime, vddNextTime)
		rtcmem.write32(rtca_vddLastRead, 3300)
		rtcmem.write32(rtca_vddAdjTime, 0)
		rtcmem.write32(rtca_magic, rtc_magic)
		Log ("run initialized")
	end
	return true
end

local function read_vdd()
	local adjTime = rtcmem.read32(rtca_vddAdjTime)
	if 0 == adjTime then return true end

	Trace (3, true)

	-- read vdd then restart
	Log ("found vddAdjTime=%.6f", adjTime/1000000)
	rtcmem.write32(rtca_vddAdjTime, 0)
	Log ("reading vdd")
	local vdd = adc.readvdd33(0)*(vdd_factor or 1)
	rtcmem.write32(rtca_vddLastRead, vdd)
	rtcmem.write32(rtca_vddNextTime, vddNextTime)	-- new vdd cycle
	adc.force_init_mode(adc.INIT_ADC)

	-- update activity time stats
	local thisTime = tmr.now() + (wakeup_delay+dsleep_delay)*rtc_rate	-- us
	rtcmem.write32(rtca_lastTime, thisTime)
	local totalTime = rtcmem.read32(rtca_totalTime)				-- ms
	rtcmem.write32(rtca_totalTime, totalTime + thisTime/1000)

	-- sleep for how long?
	adjTime = adjTime - thisTime
	Log ("vdd=%.4f restart back to ADC in %.6fs", vdd, adjTime/1000000)
	if adjTime < 1 then
		adjTime = 1
	end
	safe_dsleep (adjTime, 1)	-- enable WiFi
	return false
end

local function wifi_setup()
	if not do_WiFi then return true end

-- your access point details
	if nil == ssid then
		-- leave bssid as nil unless you really need it
		ssid, passphrase, bssid = "#SSID#", "#PASS#", nil -- "XX-XX-XX-XX-XX-XX"
	end

-- if you want to set up new WiFi then set
--	use_old_WiFi_setup = false
-- before starting a run with 'dofile("init.lua")'
	if nil == use_old_WiFi_setup then use_old_WiFi_setup = true end

-- do we want to publish the reading?
	if nil == do_Save then do_Save = true end

	saveServer = saveServer or "192.168.2.7"
	savePort   = savePort   or 11883
	netMask    = netMask    or "255.255.255.0"

-- what protocol to use to send the reading?
	save_proto = save_proto or "udp"	-- "udp", "tcp" or "mqtt"

-- how many ms to wait before aborting a wifi operation
	wifi_timeout  =  wifi_timeout  or 5000	-- waiting for wifi
	first_timeout =  first_timeout or 4000	-- waiting for 'first' response
	save_udp_timeout   =  save_udp_timeout   or 5000
	save_tcp_timeout   =  save_tcp_timeout   or 5000
	save_mqtt_timeout  =  save_mqtt_timeout  or 5000

-- how long to wait after UDP send before sleeping (missing callback, a fw/SDK bug?)
	if "udp" == save_proto then
		udp_grace_ms = udp_grace_ms or 40
	else
		udp_grace_ms = 0
	end

-- end of message marker
	save_eom = save_eom or ''

-- how often to do WiFi RFCAL
	rfcal_rate = rfcal_rate or 10

-- we want to set this up asap (to stop dhcpc)
	local ip = sta.getip()
	if not ip or ip ~= clientIP then
		Trace (1)
		sta.setip({ip=clientIP, netmask=netMask, gateway=netGW})
		Log ("static IP set to '%s' for '%s'", clientIP, clientID)
	end
	local cssid = sta.getconfig()
	if not cssid or cssid ~= ssid then
		Trace (2, true)
		wifi.setmode(wifi.STATION)
		sta.config({ssid = ssid, pwd = passphrase, save = true, auto = true})
		Log ("AP set to '%s'", ssid)
	end
	sta.status()	-- rumoured to kick start WiFi connection

	return true
end

local function domain()
	Log ("version #VERSION#")	-- will become: DATETIME DIR

-- how to execute lua programs?
-- if they were compiled then use ".lc", otherwise use ".lua"
	lua_type = lua_type or ".lc"

	local ret, magic = false, false
	if nil == clientID then
		local mac = "esp-" .. string.gsub(string.upper(sta.getmac()),":","-")
		ret, magic = pcall (function() do_file(mac, true) end)
		if ret then
			if nil == clientID then
				magic = true
			end
		else
			Log ("missing or failing setup file '%s', using default", mac)
			mac = "esp-test"
			ret, magic = pcall (function() do_file(mac, true) end)
			if not ret then
				Log ("missing or failing default setup file '%s', aborting", mac)
				return false
			end
		end
	end

	if not magic and magic_pin and magic_pin >= 0 then
		gpio.mode (magic_pin, gpio.INPUT, gpio.PULLUP)
		if 0 == gpio.read (magic_pin) then
			magic = true
		end
	end
	if magic then
		print_log = true
		Log ("aborting by magic")
		return false
	end

-- do we want to actually print messages?
	if nil == print_log    then print_log    = false end
	if nil == print_stats  then print_stats  = false end	-- memory usage
	if nil == print_dofile then print_dofile = false end	-- dofile() time
	if nil == print_trace  then print_trace  = false end

	if not setup_rtcmem() then return false end
	setup_rtcmem = nil

	local fast_dsleep = true		-- to be removed when instant dsleep committed
	if nil == use_rtctime then
		if node.dsleep_instant then
			Log ("using node.dsleep_instant")
			dsleep = node.dsleep_instant
		elseif rtctime then
			Log ("using rtctime.dsleep")
			dsleep = rtctime.dsleep
		else
			Log ("using node.dsleep")
			dsleep = node.dsleep
--			fast_dsleep = false
		end
	elseif use_rtctime then			-- froce use rtctime.dsleep
		Log ("using rtctime.dsleep")
		dsleep = rtctime.dsleep
	else					-- force use node.dsleep
		Log ("using node.dsleep")
		dsleep = node.dsleep
--		fast_dsleep = false
	end
	if nil == dsleep then
		Log ("dsleep is nil")
		return false
	end

-- some timing defaults
	if fast_dsleep then
		wakeup_delay = wakeup_delay or   1300	-- 1.3ms to enter dsleep fast
	else
		wakeup_delay = wakeup_delay or 105000	-- time to enter with node.dsleep
	end
	dsleep_delay = dsleep_delay or  70000		-- 70ms unaccounted wakeup time

	rtc_rate = rtc_rate or 1.0			-- tmr/time
	sleep_time = sleep_time or 60			-- seconds
	sleep_time = sleep_time * 1000000		-- tmr

-- when running in adc mode, do one vdd read every vddNextTime.
-- it is done with no wifi, and means an extra restart.
-- the read value is stored in rtcmem to be reported in future messages.

	vddNextTime = vddNextTime or 60*60*1000		-- 60m in ms

	if have_rtc_mem and adc_factor and vddNextTime > 0 then
		if not read_vdd() then return false end
	end
	read_vdd = nil

-- need to restart if setting a new adc mode
	local adc_mode
	if adc_factor then
		adc_mode = adc.INIT_ADC
	else
		adc_mode = adc.INIT_VDD33
		vdd_factor = vdd_factor or 1
	end
	if adc.force_init_mode(adc_mode) then
		Log ("restart to change adc_mode")
		safe_dsleep (1, 0)
		return false
	end

-- if you want to restart counting then set the new staring value
-- before starting a run with 'dofile("init.lua")'
--	runCount = nnn

-- DEBUG: do we want to enable WiFi, to allow publishing the readings?
	if nil == do_WiFi then do_WiFi = true end
	if not do_WiFi then do_Save = false end

-- select items included in the reported message
	if nil == send_times  then send_times  = true  end
	if nil == send_stats  then send_stats  = true  end
	if nil == send_mem    then send_mem    = false end
	if nil == send_reason then send_reason = true  end
	if nil == send_radio  then send_radio  = true  end

	if not wifi_setup() then return false end

	time_setup = tmr.now() - time_setup

	return true
end

if domain() then
	domain = nil
	do_file ("read")
end

