local test_count = 0

local function testConnection()
	test_count = test_count + 1
	if wifi.sta.getip() == nil then
		if 0 == test_count % 10 then
			print("IP unavaiable after " .. test_count .. " tries")
		end
	else
		tmr.stop(1)
		print("IP   avaiable after " .. test_count .. " tries" ..
			", at " .. tmr.now() ..
			": " .. wifi.sta.getip())
		collectgarbage()
		dofile ("doMQTT.lc");
	end 
end

if nil == wifi.sta.getip() then
	dofile ("getPass.lc")
	if nil == ssid or nil == pass then
		print ("missing ssid/pass")
		return
	end

	print("Setting up WIFI...")
	wifi.setmode(wifi.STATION)
	wifi.sta.config(ssid, pass)
	wifi.sta.connect()
end

tmr.alarm(1, 100, 1, testConnection)	-- 0.1s
