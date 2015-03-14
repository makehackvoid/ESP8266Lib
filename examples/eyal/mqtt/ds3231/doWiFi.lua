--collectgarbage()
used ("doWiFi")

local test_count = 0

local function resetWiFi ()
	---log ("resetWIFI")
	wifi.sta.disconnect()
	wifi.setmode(wifi.STATION)
	wifi.sta.config(ssid, passphrase)
	wifi.sta.connect()
end

local function waitforConnection()
	test_count = test_count + 1
	if wifi.sta.getip() == nil then
		if 0 == test_count % 10 then	-- announce once a second
			log ("IP unavailable after " .. test_count .. " tries")
			if use_old_WiFi_setup and test_count >= 150 then	-- 15 seconds
				resetWiFi ()
				use_old_WiFi_setup = false
				test_count = 0
			end
		end
		return
	end
	time_wifi = (tmr.now() - time_wifi) / 1000000
--	collectgarbage()

	tmr.stop(1)
	log ("IP   available after " .. test_count .. " tries: " .. wifi.sta.getip())
	if do_MQTT then
		dofile ("doMQTT"..lua_type)
--		collectgarbage()
		return
	end

	doSleep()
end

local function doWiFi()
	if not do_wifi then
		doSleep()
		return
	end

	time_wifi = tmr.now()
	if nil == wifi.sta.getip() then
		if use_old_WiFi_setup then
			log ("using old WiFi setup")
		elseif nil == ssid or nil == passphrase then
			print ("missing ssid/pass")
			return
		else
			log ("Setting up WIFI...")
			resetWiFi ()
		end
	else
		log ("Keeping active connection")
	end
	test_count = 0
	tmr.alarm(1, 100, 1, waitforConnection)	-- 0.1s
end

doWiFi()
--collectgarbage()

---log ("end")
