-- Note: this app sets a static IP early (in main.lua)

local tmr = tmr
time_wifi = done_file (tmr.now())
local print_log = print_log
local mLog = mLog
local function Log (...) if print_log then mLog ("wifi", unpack(arg)) end end
local function Trace(n, new) mTrace(5, n, new) end Trace (0, true)
used ()
out_bleep()

local wifi = wifi
local sta = wifi.sta
local eventmon

local timeout

local function doFirst()
	if "mqtt" == save_proto then
		Trace (8)
		do_file ("first-mqtt")
	elseif "tcp" == save_proto or "udp" == save_proto then
		Trace (9)
		do_file ("first-tcp")
	else
		Trace (10)
		Log ("unknown save_proto '%s'", save_proto)
		runCount = 1
		time_First = 0
		do_file ("save")
	end
end

local function cleanup()
	timeout:unregister()
	eventmon.unregister(eventmon.STA_GOT_IP)
	eventmon.unregister(eventmon.STA_DISCONNECTED)
	eventmon.unregister(eventmon.STA_DHCP_TIMEOUT)
--[[
	eventmon.unregister(eventmon.STA_CONNECTED)
	eventmon.unregister(eventmon.STA_AUTHMODE_CHANGE)
--]]
end

local function give_up()
	if eventmon then cleanup() end
	if have_rtc_mem then
		Ri(RfailHard)
--[[	-- count this failed cycle?
		if nil == runCount then
			runCount = Ri(RrunCount)
		else
			rtcmem.write32(RrunCount, runCount)
		end
--]]
	end
	Log ("WiFi unavailable - giving up")
	doSleep()
end

local retry_count = 0

local function retry()
	Trace (2)
	if retry_count >= wifi_retry_max then	-- no more retry
		Trace (9)
		give_up()
		return
	end
	retry_count = retry_count + 1

	Log ("retry")
end

local function have_connection(t, msg)
	time_wifi_ready = tmr.now()
	time_wifi = time_wifi_ready - time_wifi
	Trace (t)

	connected = true
	if eventmon then cleanup() end

	if print_log then
		Log("%s after %.6f seconds, ip=%s status=%d channel=%d",
			msg,
			time_wifi/1000000,
			(sta.getip() or "none"),
			sta.status(),
			wifi.getchannel())
	end
	if retry_count > 0 then
		Ri(RfailSoft)	-- or maybe add retry_count?
	end
	if nil == runCount then
		if newRun then
--			do_file ("first")
			doFirst()
			return
		else
			runCount = Ri(RrunCount)
		end
	end
	time_First = 0
	do_file ("save")
end

local function wait_wifi()
	tmr.wdclr()
	-- main.lua ensures ip is set

	eventmon.register(eventmon.STA_GOT_IP, function(T)
		have_connection(6, "GOT_IP")
	end)
	-- in case we were too late and missed the STA_GOT_IP event
	if wifi.STA_GOTIP == sta.status() then
		have_connection(5, "had IP")
		return
	end

	eventmon.register(eventmon.STA_DISCONNECTED, function(T)
		Log("DISCONNECTED reason %d", T.reason)
		retry()
	end)

	-- usually should not happen
	eventmon.register(eventmon.STA_DHCP_TIMEOUT, function(T)
		Log("STA_DHCP_TIMEOUT")
		retry()
	end)

--[[	these events can be ignored
	eventmon.register(eventmon.STA_CONNECTED, function(T)
		have_connection(4, "CONNECTED")
	end)

	eventmon.register(eventmon.STA_AUTHMODE_CHANGE, function(T)
		Log("AUTHMODE_CHANGE old_auth_mode=%d new_auth_mode=%d",
			T.old_auth_mode, T.new_auth_mode)
	end)
--]]
end

Trace (1)
-- shortcut in case we already have a connection (this is the most common case)
if wifi.STA_GOTIP == sta.status() then
	have_connection(7, "had IP")
else
	-- this timeout is a safety net, in case we got stuck
	eventmon = wifi.eventmon
	timeout = tmr.create()
	Log("set wifi timeout %dms", wifi_timeout)
	timeout:alarm(wifi_timeout, tmr.ALARM_SINGLE, function()
		Log("wifi timeout, status=%d", sta.status())
		give_up()
	end)

	wait_wifi()
end

