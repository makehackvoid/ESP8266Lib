local test_count = 0

local function testConnection()
	test_count = test_count + 1
	if wifi.sta.getip() == nil then
		if 0 == test_count % 10 then
			log ("IP unavailable after " .. test_count .. " tries")
		end
	else
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

tmr.alarm(1, 100, 1, testConnection)	-- 0.1s
