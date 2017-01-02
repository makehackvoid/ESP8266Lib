local tmr = tmr
time_wifi = done_file (tmr.now())
local mLog = mLog
local function Log (...) if print_log then mLog ("wifi", unpack(arg)) end end
local function Trace(n) mTrace(5, n) end Trace (0)
used ()
out_bleep()

local sta = wifi.sta
local eventmon = wifi.eventmon

local did_reset = false

local function cleanup()
	eventmon.unregister(eventmon.STA_GOT_IP)
	eventmon.unregister(eventmon.STA_DISCONNECTED)
end

local function have_connection(ip)
	time_wifi = tmr.now() - time_wifi
	Trace(1)
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

eventmon.register(eventmon.STA_GOT_IP, function(T)
	Log("got IP '%s'", T.IP)
	have_connection(T.IP)
end)

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
		sta.disconnect()
		if clientIP then
			sta.setip({ip=clientIP,netmask=netMask,gateway=netGW})
		end
		wifi.setmode(wifi.STATION)
		sta.config(ssid, passphrase, 1, bssid)
		did_reset = true
	end
end)

