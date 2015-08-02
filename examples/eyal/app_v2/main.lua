function Log (...) mLog ("main", unpack(arg)) end
time_setup = done_file (tmr.now())
used ()

local function main()
-- how to execute lua programs?
-- if they were compiled then use ".lc", otherwise use ".lua"
	lua_type = lua_type or ".lc"

	if nil == clientID then
		local mac = string.gsub(string.upper(wifi.sta.getmac()),":","-")
		do_file("esp-" .. mac, true)
		if nil == clientID then
			print ("missing setup file, using default")
			do_file("esp-test", true)
			if nil == clientID then
				print ("missing default setup file, aborting")
				abort = true
				return
			end
		end
	end
	sleep_time = sleep_time * 1000000

-- do we want to actually print messages?
	if nil == print_stats  then print_stats  = false end
	if nil == print_dofile then print_dofile = false end
	if nil == print_log    then print_log    = print_stats end

	Log("version #VERSION#")	-- will become: DATETIME DIR

	if magic_pin >= 0 then
		gpio.mode (magic_pin, gpio.INPUT, gpio.PULLUP)
		if 0 == gpio.read (magic_pin) then
			print ("aborting by magic")
			abort = true
			return
		end
	end

-- if you want to restart counting then set the new staring value
-- before starting a run with 'dofile("init.lc")'
--	runCount = nnn

-- DEBUG: do we want to enable WiFi, to allow publishing the readings?
	if nil == do_WiFi then do_WiFi = true end
	if not do_WiFi then do_Save = false end

-- your access point details
	if nil == ssid then
		ssid, passphrase = "SSID", "passphrase"
	end

-- if you want to set up new WiFi then set
--	use_old_WiFi_setup = false
-- before starting a run with 'dofile("init.lc")'
	if nil == use_old_WiFi_setup then use_old_WiFi_setup = true end

-- how many seconds to wait for automatic IP
	wifi_soft_limit = wifi_soft_limit or 6
-- how many seconds to wait for IP after reset 
	wifi_hard_limit = wifi_hard_limit or wifi_soft_limit

-- do we want to publish the reading?
	if nil == do_Save then do_Save = true end

	saveServer = saveServer or "192.168.2.7"
	savePort = savePort or 11883

	if do_WiFi then	-- speeds up WiFi?
		wifi.sta.setip({ip=clientIP,netmask=netMask,gateway=netGW})
		Log ("static IP set to %s", clientIP)
		wifi.sta.status()
	end

-- what protocol to use to send the reading? Will use save-*.lua
	save_proto = save_proto or "udp"	-- "udp" or "tcp"

	if nil == send_times then send_times = true end
	if nil == send_stats then send_stats = true end
	if nil == send_mem   then send_mem   = false end
end

if not abort then main() end
main = nil

time_setup = tmr.now() - time_setup

-- address in RTC of counters and value of magic
-- standard lua is missing the misc functions
local function rtcmem()
	have_rtc_mem = nil ~= misc
	if not have_rtc_mem then
		newRun = true	-- always fetch runCount from server
		return
	end
	rtc_magic = rtc_magic or 0xbadad0da
	rtc_magic_address     = rtc_magic_address     or 188	-- last word (192-4)
	rtc_runCount_address  = rtc_runCount_address  or (rtc_magic_address - 1*4)
	rtc_failSoft_address  = rtc_failSoft_address  or (rtc_magic_address - 2*4)
	rtc_failHard_address  = rtc_failHard_address  or (rtc_magic_address - 3*4)
	rtc_failRead_address  = rtc_failRead_address  or (rtc_magic_address - 4*4)
	rtc_lastTime_address  = rtc_lastTime_address  or (rtc_magic_address - 5*4)
	rtc_totalTime_address = rtc_totalTime_address or (rtc_magic_address - 6*4)

	newRun = rtc_magic ~= misc.rtc_mem_read_int(rtc_magic_address)
	if newRun then
		misc.rtc_mem_write_int(rtc_runCount_address, 0)
		misc.rtc_mem_write_int(rtc_failSoft_address, 0)
		misc.rtc_mem_write_int(rtc_failHard_address, 0)
		misc.rtc_mem_write_int(rtc_failRead_address, 0)
		misc.rtc_mem_write_int(rtc_lastTime_address, 0)
		misc.rtc_mem_write_int(rtc_totalTime_address, 0)
		misc.rtc_mem_write_int(rtc_magic_address, rtc_magic)
		Log ("run initialized")
	end
end

if not abort then rtcmem() end
rtcmem = nil

do_file ("read")
