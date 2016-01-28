function Log (...) mLog ("main", unpack(arg)) end
time_setup = done_file (tmr.now())
used ()

local function main()
-- how to execute lua programs?
-- if they were compiled then use ".lc", otherwise use ".lua"
	lua_type = lua_type or ".lc"

	if nil == clientID then
		local mac = string.gsub(string.upper(wifi.sta.getmac()),":","-")
		if not pcall (function() do_file("esp-" .. mac, true) end) then
			print ("missing setup file, using default")
			if not pcall (function() do_file("esp-test", true) end) then
				print ("missing default setup file, aborting")
				abort = true
				return
			end
		end
		if abort then return end
	end

-- some defaults
	sleep_rate = sleep_rate or 1.0			-- tmr/time
	sleep_time = sleep_time or 60			-- seconds
	sleep_time = sleep_time * 1000000		-- tmr
	sleep_tmr_delay = sleep_tmr_delay or 190000	-- tmr to dsleep
	adc_factor = adc_factor or 11			-- for 1m+10m ohms
	vdd_factor = vdd_factor or 1

-- do we want to actually print messages?
	if nil == print_stats  then print_stats  = false end
	if nil == print_dofile then print_dofile = false end
	if nil == print_log    then print_log    = print_stats end

	Log("version #VERSION#")	-- will become: DATETIME DIR

	if magic_pin and magic_pin >= 0 then
		gpio.mode (magic_pin, gpio.INPUT, gpio.PULLUP)
		if 0 == gpio.read (magic_pin) then
			print ("aborting by magic")
			abort = true
			return
		end
	end

-- if you want to restart counting then set the new staring value
-- before starting a run with 'dofile("init.lua")'
--	runCount = nnn

-- DEBUG: do we want to enable WiFi, to allow publishing the readings?
	if nil == do_WiFi then do_WiFi = true end
	if not do_WiFi then do_Save = false end

-- your access point details
	if nil == ssid then
		ssid, passphrase = "SSID", "PASSPHRASE"
	end

-- if you want to set up new WiFi then set
--	use_old_WiFi_setup = false
-- before starting a run with 'dofile("init.lua")'
	if nil == use_old_WiFi_setup then use_old_WiFi_setup = true end

-- settings for SDK 1.4.0 with FLASH_512K
-- how many seconds to wait for automatic IP
	wifi_soft_limit = wifi_soft_limit or 1.0	-- hot  connect, average under 0.07
-- how many seconds to wait for IP after reset 
	wifi_hard_limit = wifi_hard_limit or 5.0	-- cold connect, average under 2.2

-- do we want to publish the reading?
	if nil == do_Save then do_Save = true end

	saveServer = saveServer or "192.168.2.7"
	savePort   = savePort   or 11883
	netMask    = netMask    or "255.255.255.0"

	if do_WiFi then	-- speeds up WiFi?
		if not wifi.sta.getip() then
			wifi.sta.setip({ip=clientIP,netmask=netMask,gateway=netGW})
			Log ("static IP set to %s", clientIP)
		end
		wifi.sta.status()
	end

-- what protocol to use to send the reading?
	save_proto = save_proto or "udp"	-- "udp" or "tcp"
-- how long to wait after UDP send before sleeping (missing callback, a fw/SDK bug?)
	udp_grace_ms = udp_grace_ms or 30

-- select items included in the saved message
	if nil == send_times then send_times = true end
	if nil == send_stats then send_stats = true end
end

if not abort then main() end
main = nil

time_setup = tmr.now() - time_setup

-- address in RTC of counters and value of magic
-- standard lua is missing the rtcmem functions
local function setup_rtcmem()
	have_rtc_mem = nil ~= rtcmem
	if not have_rtc_mem then
		newRun = true	-- always fetch runCount from server
		return
	end
	rtc_magic = rtc_magic or 0x6adad0da
	rtca_magic     = rtca_magic     or 127	-- last slot
	rtca_runCount  = rtca_runCount  or (rtca_magic - 1)
	rtca_failSoft  = rtca_failSoft  or (rtca_magic - 2)
	rtca_failHard  = rtca_failHard  or (rtca_magic - 3)
	rtca_failRead  = rtca_failRead  or (rtca_magic - 4)
	rtca_lastTime  = rtca_lastTime  or (rtca_magic - 5)
	rtca_totalTime = rtca_totalTime or (rtca_magic - 6)

	newRun = rtc_magic ~= rtcmem.read32(rtca_magic)
	if newRun then
		rtcmem.write32(rtca_runCount, 0)
		rtcmem.write32(rtca_failSoft, 0)
		rtcmem.write32(rtca_failHard, 0)
		rtcmem.write32(rtca_failRead, 0)
		rtcmem.write32(rtca_lastTime, 0)
		rtcmem.write32(rtca_totalTime, 0)
		rtcmem.write32(rtca_magic, rtc_magic)
		Log ("run initialized")
	end
end

if not abort then setup_rtcmem() end
setup_rtcmem = nil

do_file ("read")
