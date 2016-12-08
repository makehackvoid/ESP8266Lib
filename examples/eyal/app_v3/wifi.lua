local tmr = tmr
time_wifi = done_file (tmr.now())
local mLog = mLog
local function Log (...) if print_log then mLog ("wifi", unpack(arg)) end end
local out_toggle = out_toggle
local sta = wifi.sta
used ()
out_bleep()

local check_rate = 1000			-- checks per second (1ms period)
local soft_limit = wifi_soft_limit*check_rate
local hard_limit = wifi_hard_limit*check_rate

local check_count = 0
local wifi_status = -1

local function resetWiFi ()
	Log ("resetWIFI")
	sta.disconnect()
	if clientIP then
		sta.setip({ip=clientIP,netmask=netMask,gateway=netGW})
	end
	wifi.setmode(wifi.STATION)
	sta.config(ssid, passphrase, 1, bssid)
end

local function haveConnection()
	time_wifi = tmr.now() - time_wifi
	Log ("WiFi   available after %.3f seconds, ip=%s",
		check_count/check_rate, sta.getip())
	if nil == runCount then
		if newRun then
			do_file ("first")
			return
		end
		runCount = incrementCounter(rtca_runCount)
	end
	time_First = 0
	do_file ("save")
end

local function waitforConnection()
	check_count = check_count + 1
	local new_status = sta.status()
	if new_status ~= wifi_status then
		Log ("status %d", new_status)
		wifi_status = new_status
	end
	if 5 ~= new_status then
		out_toggle()
		if 0 == check_count % check_rate then	-- announce once a second
			Log ("WiFi unavailable after %d seconds, status=%d",
				check_count/check_rate, wifi_status)
			if use_old_WiFi_setup and check_count >= soft_limit then
				resetWiFi ()
				use_old_WiFi_setup = false
				check_count = 0		-- restart counter
				incrementCounter(rtca_failSoft)
			elseif check_count >= hard_limit then
				tmr.stop(1)
				incrementCounter(rtca_failHard)
				Log ("WiFi unavailable - giving up")
				doSleep()
			end
		end
	else
		out_set(gpio.LOW)
		tmr.stop(1)
		haveConnection()
	end
end

local function doWiFi()
	local status = sta.status()
	if 5 ~= status then
		if use_old_WiFi_setup then
			Log ("using old WiFi setup")
		elseif nil == ssid or nil == passphrase then
			print ("missing ssid/pass")
			return
		else
			Log ("Setting up WIFI...")
			resetWiFi ()
		end
		check_count = 0
		tmr.alarm(1, 1000/check_rate, 1, waitforConnection)
	else
		Log ("Keeping active connection")
		haveConnection()
	end
end

doWiFi()
