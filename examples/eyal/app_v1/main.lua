time_dofile = time_dofile + (tmr.now()-start_dofile)
m = m + 1; mods[m] = "main"
used ()

local function main()
	local gpio0  = 3	-- ESP-01, clixx o
	local gpio2  = 4	-- ESP-01, clixx i
	local gpio4  = 2
	local gpio5  = 1
--	local gpio12 = 6
--	local gpio13 = 7
--	local gpio14 = 5

-- do we want to actually print messages?
	print_usage = print_usage or false
	print_log = print_log or print_usage

	Log("version #VERSION#")	-- will become: DATETIME DIR

-- which is the magic pin?
	magic_pin = magic_pin or gpio5		-- '-1' to disable the magic
	if magic_pin >= 0 then
		gpio.mode (magic_pin, gpio.INPUT, gpio.PULLUP)
		if 0 == gpio.read (magic_pin) then
			print ("aborting by magic")
			abort = true
			return
		end
	end

-- which pins is the i2c attached to?
	if nil == i2c_SDA then
		i2c_SDA, i2c_SCL = gpio2, gpio0	-- '-1' to disable i2c
	end

-- which pin is the one-wire attached to?
	ow_pin = ow_pin or gpio4		-- '-1' to disable ow

-- which device to read? Will use read-*.lua
	read_device = read_device or "ds3231"	--  ds3231 or ds18b20

-- your access point details
	if nil == ssid then
		ssid, passphrase = "ssid", "passphrase"
	end

-- if you want to set up the WiFi then set
--	use_old_WiFi_setup = false
-- before starting a run with 'dofile("init.lc")'
	use_old_WiFi_setup = use_old_WiFi_setup or true

-- how many seconds to wait for automatic IP
	wifi_soft_limit =  5
-- how many seconds to wait for IP after reset 
	wifi_hard_limit = 10

-- if you want to restart counting then set the new staring value
-- before starting a run with 'dofile("init.lc")'
--	runCount = nnn

-- where to save readings
	saveServer = saveServer or "192.168.3.7"
	savePort = savePort or 11883
	clientID = clientID or "esp-test"	-- is also save ID

-- what protocol to use to send the reading? Will use save-*.lua
	save_proto = save_proto or "udp"	-- "udp" or "tcp"

-- how to execute lua programs?
-- if they were compiled then use ".lc", otherwise use ".lua"
	lua_type = lua_type or ".lc"

-- how long we sleep between runs?
-- 0 to disable. negative to delay (then restart) instead.
	sleep_time = sleep_time or 0
-- rate > 1 if tmr.now() is slow
	sleep_rate = sleep_rate or 1.0

-- DEBUG: do we want to enable WiFi, to allow publishing the readings?
	do_WiFi = do_WiFi or true

-- do we want to publish the reading ?
	do_Save = do_Save or true
	if do_Save then
		saveServer = saveServer or Broker_Address
		savePort = savePort or 11883
	end

-- address in RTC of counters and value of magic
-- standard lua is missing the misc functions
	have_rtc_mem = nil ~= misc
	if have_rtc_mem then
		rtc_magic_address = rtc_magic_address or 188	-- last word (192-4)
		rtc_magic = rtc_magic or 0xbadad0da

		rtc_runCount_address = rtc_runCount_address or (rtc_magic_address - 1*4)
		rtc_failSoft_address = rtc_failSoft_address or (rtc_magic_address - 2*4)
		rtc_failHard_address = rtc_failHard_address or (rtc_magic_address - 3*4)
		rtc_failRead_address = rtc_failRead_address or (rtc_magic_address - 4*4)

		newRun = rtc_magic ~= misc.rtc_mem_read_int(rtc_magic_address)
		if newRun then
			misc.rtc_mem_write_int(rtc_runCount_address, 0)
			misc.rtc_mem_write_int(rtc_failSoft_address, 0)
			misc.rtc_mem_write_int(rtc_failHard_address, 0)
			misc.rtc_mem_write_int(rtc_failRead_address, 0)
			misc.rtc_mem_write_int(rtc_magic_address, rtc_magic)
			Log ("run initialized")
		end
	else
		newRun = true	-- always fetch runCount from server
	end
end

main()

do_file("read-"..read_device)

-- leave this line at end of the file --
