local mLog = mLog
local function Log (...) if print_log then mLog ("main", unpack(arg)) end end
time_setup = done_file (tmr.now())
local function Trace(n, new) mTrace(3, n, new) end Trace (0, true)
used ()
out_bleep()

local wifi = wifi
local sta = wifi.sta
local Rr = rtcmem.read32
local Rw = rtcmem.write32

-- address in RTC of counters and value of magic
local function setup_rtcmem()
	have_rtc_mem = nil ~= rtcmem
	if not have_rtc_mem then
		newRun = true	-- always fetch runCount from server
		return true
	end
	rtc_magic        = rtc_magic        or 0x6adadad1	-- keep below 0x80000000
	Rmagic       = Rmagic       or 127		-- last slot
	RrunCount    = RrunCount    or (Rmagic -  1)
	RfailSoft    = RfailSoft    or (Rmagic -  2)
	RfailHard    = RfailHard    or (Rmagic -  3)
	RfailRead    = RfailRead    or (Rmagic -  4)
	RlastTime    = RlastTime    or (Rmagic -  5)
	RtotalTime   = RtotalTime   or (Rmagic -  6)
	RtimeLeft    = RtimeLeft    or (Rmagic -  7)
	RtracePointH = RtracePointH or (Rmagic -  8)
	RtracePointL = RtracePointL or (Rmagic -  9)
	RvddNextTime = RvddNextTime or (Rmagic - 10)	-- ms to next vdd read
	RvddLastRead = RvddLastRead or (Rmagic - 11)
	RvddAdjTime  = RvddAdjTime  or (Rmagic - 12)
	RfailTime    = RfailTime    or (Rmagic - 13)	-- unreported uptime

	newRun = newRun or (rtc_magic ~= Rr(Rmagic))
	if newRun then
		Rw(RrunCount, 0)
		Rw(RfailSoft, 0)
		Rw(RfailHard, 0)
		Rw(RfailRead, 0)
		Rw(RlastTime, 0)
		Rw(RtotalTime, 0)
		Rw(RtimeLeft, 0)
		Rw(RtracePointH, 0xffffffff)
		Rw(RtracePointL, 0xffffffff)
		last_trace_h, last_trace_l = 0xffffffff, 0xffffffff
		Rw(RvddNextTime, vddNextTime)
		Rw(RvddLastRead, 3300)
		Rw(RvddAdjTime, 0)
		Rw(RfailTime, 0)
		Rw(Rmagic, rtc_magic)
		Log ("run initialized")
	end
	return true
end

local function read_vdd()
	local adjTime = Rr(RvddAdjTime)
	if 0 == adjTime then return true end

	Trace (3, true)

	-- read vdd then restart
	Log ("found vddAdjTime=%.6f", adjTime/1000000)
	Rw(RvddAdjTime, 0)
	Log ("reading vdd")
	local vdd = adc.readvdd33(0)*(vdd_factor or 1)
	Rw(RvddLastRead, vdd)
	Rw(RvddNextTime, vddNextTime)	-- new vdd cycle
	adc.force_init_mode(adc.INIT_ADC)

	-- update activity time stats
	local thisTime = tmr.now() + (dsleep_delay+wakeup_delay)*rtc_rate	-- us
	Rw(RlastTime, thisTime)
--	local totalTime = Rr(RtotalTime)				-- ms
--	Rw(RtotalTime, totalTime + thisTime/1000)
	Ri(RtotalTime, thisTime/1000)

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
	connected = false
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
	wifi_timeout       = wifi_timeout       or 6000	-- 6s
	wifi_retry_max     = wifi_retry_max     or    0	-- times to retry (default none)
	first_timeout      = first_timeout      or 4000	-- waiting for 'first' response
	save_udp_timeout   = save_udp_timeout   or 5000
	save_tcp_timeout   = save_tcp_timeout   or 5000
	save_mqtt_timeout  = save_mqtt_timeout  or 5000

-- yield time to allow wifi to make a connection
	if not read_delay then
		read_delay = 1
	elseif read_delay < 1 then
		read_delay = 1
	end

-- how long to wait after UDP send before sleeping (missing callback, a fw/SDK bug?)
	if "udp" == save_proto then
		udp_grace_ms = udp_grace_ms or 50
	end

-- end of message marker
	save_eom = save_eom or ''

-- we want to set this early (to limit the channel scan)
if wifi.getcountry and wifi.setcountry then
	local country = country
	if nil == country then
		country = "AU"
	end
	local country_old = wifi.getcountry().country
	if country ~= country_old then
		wifi.setcountry({country=country, start_ch=6, end_ch=11, policy=wifi.COUNTRY_MANUAL}) -- .COUNTRY_AUTO or .COUNTRY_MANUAL
		Log ("wifi.country set to '%s' (was '%s') channels [6,11]", country, (country_old or "--"))
	end
end

-- we want to set this early (to stop dhcpc)
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

	if not adc_en_pin then
		adc_en_pin = 0
	elseif adc_en_pin > 0 then
		gpio.mode (adc_en_pin, gpio.OUTPUT)
		gpio.write(adc_en_pin, gpio.LOW)
	end

-- do we want to actually print messages?
	if nil == print_log then
		if nil == log_pin then
			print_log = false
		else
			gpio.mode (log_pin, gpio.INPUT, gpio.PULLUP)
			if 0 == gpio.read (log_pin) then
				print_log = true
			else
				print_log = false
			end
		end
	end

-- see save.lua for the meaning of these numers:
	local code, reason, cause = node.bootreason()
	Log ("code %d reason %d cause %d", code, reason, cause or 99)

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
		dsleep_delay = fast_dsleep_delay or   3000	-- time to sleep with node.dsleep(,,1)
	else
		dsleep_delay = slow_dsleep_delay or 105000	-- time to sleep with node.dsleep(,,0)
	end
	wakeup_delay = wakeup_delay or  70000		-- 70ms unaccounted wakeup time

	rtc_rate = rtc_rate or 1.0			-- tmr/time

	sleep_time = sleep_time or 60			-- cycle length, seconds
-- how often to do WiFi RFCAL
--	rfcal_rate = rfcal_rate or 10
	rfcal_rate = rfcal_rate or (3600/sleep_time+1)	-- once an hour
	sleep_time = sleep_time * 1000000		-- us

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

-- if you want to restart counting then set the new value (nnn) before starting:
--	runCount = nnn dofile("init.lua")
-- or, to clear all rtc registers:
--	newRun = true dofile("init.lua")
-- or both

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

