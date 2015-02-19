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
		dofile ("doMQTT.lc");
	end 
end

if nil == wifi.sta.getip() then
	if nil == ssid or nil == passphrase then
		print ("missing ssid/pass")
		return
	end

	log ("Setting up WIFI...")
	wifi.setmode(wifi.STATION)
	wifi.sta.config(ssid, passphrase)
	wifi.sta.connect()
end

tmr.alarm(1, 100, 1, testConnection)	-- 0.1s
