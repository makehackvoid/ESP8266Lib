local mLog = mLog
local function Log (...) if print_log then mLog ("main", unpack(arg)) end end
time_setup = done_file (tmr.now())
used ()
out_bleep()

local sta = wifi.sta
local rtcmem = rtcmem

local function main()
-- how to execute lua programs?
-- if they were compiled then use ".lc", otherwise use ".lua"
	lua_type = lua_type or ".lc"

	if nil == clientID then
		local mac = string.gsub(string.upper(sta.getmac()),":","-")
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
	rtc_rate = rtc_rate or 1.0			-- tmr/time
	sleep_time = sleep_time or 60			-- seconds
	sleep_time = sleep_time * 1000000		-- tmr

	if nil ~= rtctime then
		wakeup_delay = wakeup_delay or   1300	-- 1.3ms to enter with rtctime.dsleep
	else
		wakeup_delay = wakeup_delay or 105000	-- time to enter with node.dsleep
	end
	dsleep_delay = dsleep_delay or  70000	-- 70ms unaccounted wakeup time

-- need to restart if setting a new adc mode
	local adc_mode
	if adc_factor then
		adc_mode = adc.INIT_ADC
		vdd_factor = nil	-- cannot do both
	else
		adc_mode = adc.INIT_VDD33
		vdd_factor = vdd_factor or 1
	end
	if adc.force_init_mode(adc_mode) then
		node.restart()
	end

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

-- select items included in the reported message
	if nil == send_times  then send_times  = true end
	if nil == send_reason then send_reason = true end
	if nil == send_stats  then send_stats  = true end
	if nil == send_radio  then send_radio  = true end
end

if not abort then main() end
main = nil

local function wifi_setup()
-- your access point details
	if nil == ssid then
		-- leave bssid as nil unless you really need it
		ssid, passphrase, bssid = "SSID", "PASSPHRASE", "B0-48-7A-C2-B8-CC"
	end

-- if you want to set up new WiFi then set
--	use_old_WiFi_setup = false
-- before starting a run with 'dofile("init.lua")'
	if nil == use_old_WiFi_setup then use_old_WiFi_setup = true end

-- settings for SDK 1.4.0 with FLASH_512K
-- how many seconds to wait for automatic IP
	wifi_soft_limit = wifi_soft_limit or 5	-- hot  connect, average under 0.07
-- how many seconds to wait for IP after reset 
	wifi_hard_limit = wifi_hard_limit or 10	-- cold connect, average under 2.2

-- do we want to publish the reading?
	if nil == do_Save then do_Save = true end

	saveServer = saveServer or "192.168.2.7"
	savePort   = savePort   or 11883
	netMask    = netMask    or "255.255.255.0"

-- what protocol to use to send the reading?
	save_proto = save_proto or "udp"	-- "udp" or "tcp"
-- how long to wait after UDP send before sleeping (missing callback, a fw/SDK bug?)
	udp_grace_ms = udp_grace_ms or 30

-- how often to do WiFi RFCAL
	rfcal_rate = rfcal_rate or 10

-- we want to set this up asap (to stop dhcpc)
	local ip = sta.getip()
	if not ip or ip ~= clientIP then
		sta.setip({ip=clientIP,netmask=netMask,gateway=netGW})
		Log ("static IP set to '%s'", clientIP)
	end
	local cssid = sta.getconfig()
	if not cssid or cssid ~= ssid then
		wifi.setmode(wifi.STATION)
		sta.config(ssid, passphrase, 1, bssid)
		Log ("AP set to '%s'", ssid)
	end
	sta.status()	-- rumoured to kick start WiFi connection
end

if not abort and do_WiFi then wifi_setup() end
wifi_setup = nil

time_setup = tmr.now() - time_setup

-- address in RTC of counters and value of magic
-- standard lua is missing the rtcmem functions
local function setup_rtcmem()
	if nil ~= rtctime then
		if 0 == rtctime.get() then	-- was never set
			rtctime.set(0,0)
		end
	end

	have_rtc_mem = nil ~= rtcmem
	if not have_rtc_mem then
		newRun = true	-- always fetch runCount from server
		return
	end
	rtc_magic      = rtc_magic      or 0x6adad0da
	rtca_magic     = rtca_magic     or 127		-- last slot
	rtca_runCount  = rtca_runCount  or (rtca_magic - 1)
	rtca_failSoft  = rtca_failSoft  or (rtca_magic - 2)
	rtca_failHard  = rtca_failHard  or (rtca_magic - 3)
	rtca_failRead  = rtca_failRead  or (rtca_magic - 4)
	rtca_lastTime  = rtca_lastTime  or (rtca_magic - 5)
	rtca_totalTime = rtca_totalTime or (rtca_magic - 6)
	rtca_timeLeft  = rtca_timeLeft  or (rtca_magic - 7)

	newRun = rtc_magic ~= rtcmem.read32(rtca_magic)
	if newRun then
		rtcmem.write32(rtca_runCount, 0)
		rtcmem.write32(rtca_failSoft, 0)
		rtcmem.write32(rtca_failHard, 0)
		rtcmem.write32(rtca_failRead, 0)
		rtcmem.write32(rtca_lastTime, 0)
		rtcmem.write32(rtca_totalTime, 0)
		rtcmem.write32(rtca_timeLeft, 0)
		rtcmem.write32(rtca_magic, rtc_magic)
		Log ("run initialized")
	end
end

if not abort then setup_rtcmem() end
setup_rtcmem = nil

do_file ("read")
