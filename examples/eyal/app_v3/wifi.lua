-- Note: this app sets a static IP early (in main.lua) so there is no need to wait
-- for a STA_GOT_IP event

local tmr = tmr
time_wifi = done_file (tmr.now())
local mLog = mLog
local function Log (...) if print_log then mLog ("wifi", unpack(arg)) end end
local function Trace(n, new) mTrace(5, n, new) end Trace (0, true)
used ()
out_bleep()

local wifi = wifi
local sta = wifi.sta
local eventmon = wifi.eventmon
local timeout = tmr.create()
local toggled = false

local function cleanup()
	timeout:unregister()
	eventmon.unregister(eventmon.STA_GOT_IP)
	eventmon.unregister(eventmon.STA_DISCONNECTED)
--[[
	eventmon.unregister(eventmon.STA_CONNECTED)
	eventmon.unregister(eventmon.STA_AUTHMODE_CHANGE)
	eventmon.unregister(eventmon.STA_DHCP_TIMEOUT)
--]]
end

local function give_up()
	cleanup()
	incrementCounter(RfailHard)
--[[	-- count this failed cycle?
	if have_rtc_mem then
		if nil == runCount then
			incrementCounter(RrunCount)
		else
			rtcmem.write32(RrunCount, runCount)
		end
	end
--]]
	Log ("WiFi unavailable - giving up")
	doSleep()
end

local retry_count = 0

local function dummy()
end

local function retry()
	Trace (2)
	if retry_count >= wifi_retry_max or wifi_retry_timeout <= 0 then	-- no more retry
		Trace (9)
		give_up()
		return
	end
	retry_count = retry_count + 1

	tmr.wdclr()
if true then
	toggled = true
Log ("suspend WiFi")
	wifi.suspend({50000, dummy, dummy, true})	-- toggle for 1ms
else
	Log ("reset WiFi, state=%d", wifi.suspend())
	if 1 == wifi.suspend() then
Log ("resume WiFi")
		toggled = true
		wifi.resume(dummy)
	else
		toggled = true
Log ("suspend WiFi")
		wifi.suspend({50000, dummy, dummy, true})	-- toggle for 1ms
	end
Log ("reseted WiFi")
end
end

local function retry_old()
	Trace (2)
	if retry_count >= wifi_retry_max or wifi_retry_timeout <= 0 then	-- no more retry
		Trace (9)
		give_up()
		return
	end
	retry_count = retry_count + 1

	Log ("reset WiFi")
	local changed = false
	sta.disconnect()
	local ip, nm, gw = sta.getip()
	if not ip or ip ~= clientIP or not gw or gw ~= netGW then
		Trace (7, true)
		changed = true
	end
	sta.setip({ip=clientIP,netmask=netMask,gateway=netGW})	-- always set

	local cssid, cpass = sta.getconfig()
	if not cssid or cssid ~= ssid or not cpass or cpass ~= passphrase then
		Trace (8, true)
		changed = true
	end
	wifi.setmode(wifi.STATION)	-- always set
	sta.config({ssid = ssid, pwd = passphrase, save = true, auto = true})

	-- retry even if no change...

	Log("set retry wifi timeout %dms", wifi_retry_timeout)
	timeout:alarm(wifi_retry_timeout, tmr.ALARM_SINGLE, function()
		Trace (3)
		Log("reconnection timeout again, status=%d", sta.status())
		retry()
	end)
end

local function have_connection(t, msg)
	time_wifi_ready = tmr.now()
	time_wifi = time_wifi_ready - time_wifi
	Trace (t)
	cleanup()
	Log("%s after %.6f seconds, ip=%s status=%d channel=%d",
		msg,
		time_wifi/1000000,
		(sta.getip() or "none"),
		sta.status(),
		wifi.getchannel())
	if retry_count > 0 then
		incrementCounter(RfailSoft)
	end
	if nil == runCount then
		if newRun then
			do_file ("first")
			return
		else
			runCount = incrementCounter(RrunCount)
		end
	end
	time_First = 0
	do_file ("save")
end

local function dowifi()
	Trace (1)
	tmr.wdclr()
	-- main.lua ensures ip is set

	eventmon.register(eventmon.STA_GOT_IP, function(T)
		have_connection(6, "GOT_IP")
	end)

--[[
	eventmon.register(eventmon.STA_CONNECTED, function(T)
		have_connection(4, "CONNECTED")
	end)

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
		retry()
	end)

	-- in case we were too late and missed the STA_GOT_IP event
	if wifi.STA_GOTIP == sta.status() then
		have_connection(5, "had IP")
		return
	end

	if wifi_first_timeout > 0 then
		Log("set main  wifi timeout %dms", wifi_first_timeout)
		timeout:alarm(wifi_first_timeout, tmr.ALARM_SINGLE, function()
			Log("connection timeout, status=%d", sta.status())
			retry()
		end)
	else
		eventmon.register(eventmon.STA_DISCONNECTED, function(T)
			Log("DISCONNECTED reason %d", T.reason)
			if toggled then
				toggled = false
			else
				retry()
			end
		end)
	end

end

dowifi()

