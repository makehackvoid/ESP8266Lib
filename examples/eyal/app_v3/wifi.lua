-- Note: this app sets a static IP early (in main.lua) so there is no need to wait
-- for a STA_GOT_IP event

local tmr = tmr
time_wifi = done_file (tmr.now())
local mLog = mLog
local function Log (...) if print_log then mLog ("wifi", unpack(arg)) end end
local function Trace(n, new) mTrace(5, n, new) end Trace (0, true)
used ()
out_bleep()

local sta = wifi.sta
local eventmon = wifi.eventmon
local timeout = tmr.create()

local function cleanup()
	timeout:unregister()
	eventmon.unregister(eventmon.STA_CONNECTED)
	eventmon.unregister(eventmon.STA_GOT_IP)
	eventmon.unregister(eventmon.STA_DISCONNECTED)
--[[
	eventmon.unregister(eventmon.STA_AUTHMODE_CHANGE)
	eventmon.unregister(eventmon.STA_DHCP_TIMEOUT)
--]]
end

local function give_up()
	cleanup()
	incrementCounter(rtca_failHard)
--[[	-- count this failed cycle?
	if have_rtc_mem then
		if nil == runCount then
			incrementCounter(rtca_runCount)
		else
			rtcmem.write32(rtca_runCount, runCount)
		end
	end
--]]
	Log ("WiFi unavailable - giving up")
	doSleep()
end

local retry_count = 0

local function retry()
	Trace(2)
	Log ("reset WiFi")
	local changed = false
	sta.disconnect()
	local ip, nm, gw = sta.getip()
	if not ip or ip ~= clientIP or not gw or gw ~= netGW then
		Trace(7, true)
		changed = true
	end
	sta.setip({ip=clientIP,netmask=netMask,gateway=netGW})	-- always set

	local cssid, cpass = sta.getconfig()
	if not cssid or cssid ~= ssid or not cpass or cpass ~= passphrase then
		Trace(8, true)
		changed = true
	end
	wifi.setmode(wifi.STATION)	-- always set
	sta.config({ssid = ssid, pwd = passphrase, save = true, auto = true})

	if not changed then		-- no change, do not retry
--	if retry_count >= 2 then	-- already tried twice
		Trace(9)
		give_up()
		return
	end
	retry_count = retry_count + 1

	timeout:alarm(wifi_timeout, tmr.ALARM_SINGLE, function()
		Trace(3)
		Log("connection timeout again, status=%d", sta.status())
		give_up()
	end)
end

local function have_connection(ip)
	time_wifi = tmr.now() - time_wifi
	cleanup()
	Log ("WiFi available after %.6f seconds, ip=%s",
		time_wifi/1000000, ip)
	if retry_count > 0 then
		incrementCounter(rtca_failSoft)
	end
	if nil == runCount then
		if newRun then
			do_file ("first")
			return
		else
			runCount = incrementCounter(rtca_runCount)
		end
	end
	time_First = 0
	do_file ("save")
end

local function dowifi()
	Trace(1)
	tmr.wdclr()
	-- main.lua ensures ip is set
	eventmon.register(eventmon.STA_CONNECTED, function(T)
		Trace(4)
		local ip = sta.getip()
		Log("CONNECTED as %s status=%d channel=%d", ip, sta.status(), T.channel)
--		have_connection(ip)
	end)

	if wifi.STA_GOTIP == sta.status() then
		Trace(5)
		local ip = sta.getip()
		Log("had wifi  as %s status=%d", (ip or "none"), wifi.STA_GOTIP)
		have_connection(ip)
		return
	end

	timeout:alarm(wifi_timeout, tmr.ALARM_SINGLE, function()
		Log("connection timeout, status=%d", sta.status())
		retry()
	end)

	eventmon.register(eventmon.STA_GOT_IP, function(T)
		Trace(6)
		Log("GOT_IP '%s'", T.IP)
		have_connection(T.IP)
	end)

--[[
	eventmon.register(eventmon.STA_DISCONNECTED, function(T)
		Log("DISCONNECTED reason %d", T.reason)
		retry()
	end)

	eventmon.register(eventmon.STA_AUTHMODE_CHANGE, function(T)
		Log("AUTHMODE_CHANGE old_auth_mode=%d new_auth_mode=%d",
			T.old_auth_mode, T.new_auth_mode)
	end)
--]]

	eventmon.register(eventmon.STA_DHCP_TIMEOUT, function(T)
		Log("STA_DHCP_TIMEOUT")
	end)
end

dowifi()

