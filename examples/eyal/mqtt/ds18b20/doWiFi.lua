local test_count

local function resetWiFi ()
	log ("ReSetting WIFI...")
	wifi.setmode(wifi.STATION)
	wifi.sta.config(ssid, passphrase)
	wifi.sta.connect()
end

local function testConnection()
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
	else
		time_WiFi = (tmr.now() - time_WiFi) / 1000000
		tmr.stop(1)
		log ("IP   available after " .. test_count .. " tries: "
			.. wifi.sta.getip())
		collectgarbage()
		if do_MQTT then
			dofile ("doMQTT"..lua_type);
		else
			log ("not doing MQTT");
			node.dsleep (sleep_time);
		end
	end 
end

time_WiFi = tmr.now()
if nil == wifi.sta.getip() then
	if use_old_WiFi_setup then
		log ("using old WiFi setup")
	elseif nil == ssid or nil == passphrase then
		print ("missing ssid/pass")
		return
	else
		log ("Setting up WIFI...")
		wifi.setmode(wifi.STATION)
		wifi.sta.config(ssid, passphrase)
	end
	wifi.sta.connect()
end

test_count = 0
tmr.alarm(1, 100, 1, testConnection)	-- 0.1s
