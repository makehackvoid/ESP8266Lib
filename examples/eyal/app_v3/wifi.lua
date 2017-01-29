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

local function cleanup()
	eventmon.unregister(eventmon.STA_CONNECTED)
--	eventmon.unregister(eventmon.STA_GOT_IP)
	eventmon.unregister(eventmon.STA_DISCONNECTED)
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

local retry_done = false

local function retry()
	if retry_done then
		Trace(3)
		give_up()
		return
	end

	Trace(2)
	Log ("reset WiFi")
	local changed = false
	sta.disconnect()
	local ip, nm, gw = sta.getip()
	if not ip or ip ~= clientIP or not gw or gw ~= netGW then
		Trace(7, true)
		sta.setip({ip=clientIP,netmask=netMask,gateway=netGW})
		changed = true
	end
	local cssid, cpass = sta.getconfig()
	if not cssid or cssid ~= ssid or not cpass or cpass ~= passphrase then
		Trace(8, true)
		wifi.setmode(wifi.STATION)
--		sta.config(ssid, passphrase, 1, bssid)	-- deprecated
		sta.config({ssid = ssid, pwd = passphrase, save = true, auto = true})
		changed = true
	end
	if not changed then
		Trace(9)
		give_up()
		return
	end
	retry_done = true
end

local function have_connection(ip)
	time_wifi = tmr.now() - time_wifi
	cleanup()
	Log ("WiFi available after %.6f seconds, ip=%s",
		time_wifi/1000000, ip)
	if retry_done then
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
		Log("CONNECTED as %s status=%d", ip, sta.status())
		have_connection(ip)
	end)

	if wifi.STA_GOTIP == sta.status() then
		Trace(5)
		local ip = sta.getip()
		Log("had wifi  as %s status=%d", (ip or "none"), wifi.STA_GOTIP)
		have_connection(ip)
		return
	end

--[[
	eventmon.register(eventmon.STA_GOT_IP, function(T)
		Trace(6)
		Log("got IP '%s'", T.IP)
--		have_connection(T.IP)
	end)
--]]

	eventmon.register(eventmon.STA_DISCONNECTED, function(T)
		Log("disconnected, reason %d", T.reason)
		retry()
	end)
end

dowifi()

