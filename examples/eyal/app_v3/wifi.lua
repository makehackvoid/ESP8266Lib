-- Note: this app sets a static IP early (in main.lua) so there is no need to wait
-- for a STA_GOT_IP event

local tmr = tmr
time_wifi = done_file (tmr.now())
local mLog = mLog
local function Log (...) if print_log then mLog ("wifi", unpack(arg)) end end
local function Trace(n, new) mTrace(5, n, new) end Trace (0)
used ()
out_bleep()

local sta = wifi.sta
local eventmon = wifi.eventmon

local did_reset = false

local function cleanup()
	eventmon.unregister(eventmon.STA_CONNECTED)
--	eventmon.unregister(eventmon.STA_GOT_IP)
	eventmon.unregister(eventmon.STA_DISCONNECTED)
end

local function have_connection(ip)
	time_wifi = tmr.now() - time_wifi
	tmr.stop (1)	------------------------- DEBUG -------------
--	Trace(1)
	cleanup()
	Log ("WiFi available after %.6f seconds, ip=%s",
		time_wifi/1000000, ip)
	if did_reset then
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

if 5 == sta.status() then
	Trace(5)
	local ip = sta.getip()
	Log("had IP '%s'", ip)
	have_connection(ip)
else
	local last_status = -1	---------------------- DEBUG ------------------
	tmr.alarm (1, 10, 1, function()
		if 5 == status then
			tmr.stop (1)
			return
		end
		local status = sta.status()
		if last_status ~= status then
			last_status = status
			if status < 0 then status = 8
			elseif status > 5 then status = 9
			else status = 10+status end
			Log("DEBUG status %d", status)
			Trace(status)
		end
	end)
end

eventmon.register(eventmon.STA_CONNECTED, function(T)
	Trace(4)
	local ip = sta.getip()
	Log("CONNECTED as %s status=%d", ip, wifi.sta.status())
	have_connection(ip)
end)

--[[
eventmon.register(eventmon.STA_GOT_IP, function(T)
	Trace(6)
	Log("got IP '%s'", T.IP)
--	have_connection(T.IP)
end)
--]]

eventmon.register(eventmon.STA_DISCONNECTED, function(T)
	Log("disconnected, reason %d", T.reason)
	if did_reset then
		Trace(3)
		cleanup()
		incrementCounter(rtca_failHard)
		Log ("WiFi unavailable - giving up")
		doSleep()
	else
		Trace(2)
		Log ("reset WiFi")
		changed = false
		sta.disconnect()
		local ip, nm, gw = sta.getip()
		if not ip or ip ~= clientIP or not gw or gw ~= netGW then
			Trace(7)
			sta.setip({ip=clientIP,netmask=netMask,gateway=netGW})
			changed = true
		end
		local cssid, cpass = sta.getconfig()
		if not cssid or cssid ~= ssid or not cpass or cpass ~= passphrase then
			Trace(8)
			wifi.setmode(wifi.STATION)
--			sta.config(ssid, passphrase, 1, bssid)	-- deprecated
			sta.config({ssid = ssid, pwd = passphrase, save = true, auto = true})
			changed = true
		end
		if not changed then
			Trace(9)
			tmr.stop (1)	------------------------- DEBUG -------------
			cleanup()
			incrementCounter(rtca_failHard)
			Log ("WiFi unavailable - giving up")
			doSleep()
		end
		did_reset = true
	end
end)

