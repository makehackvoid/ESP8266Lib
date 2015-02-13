
function testConnection()
	test_count = test_count + 1
	if wifi.sta.getip() == nil then
		if 0 == test_count % 10 then
			print("IP unavaiable after " .. test_count .. " tries")
		end
	else
		tmr.stop(1)
		print("Config done after " .. test_count .. " tries" ..
			", at " .. tmr.now() ..
			", IP is " .. wifi.sta.getip())
		collectgarbage()
		StartProgram()
	end 
end

function StartProgram()
     m = mqtt.Client("clientid", 2)	-- , "user", "password")

     m:on("offline", function(conn)
	print ("offline at " .. tmr.now())
	node.dsleep(2*1000000)		-- 2s
     end)

print ("m:connect")
     m:connect(Server_IP_Address, Server_Port, 0, function(conn)
	print("connected at " .. tmr.now())
	print("publish temperature "..temp.."'C")
	m:publish("testing/temp", (runCount..": "..temp), 0, 1, function(conn)
		print ("published at " .. tmr.now())
		m:close();
	end)
     end)
end

-- before starting a new test:
--	file.remove ("runCount") ; node.restart()

if nil == wifi.sta.getip() then
	dofile ("getPass.lua")
	if nil == ssid or nil == pass then
		print ("missing ssid/pass")
		return
	end

	print("Setting up WIFI...")
	wifi.setmode(wifi.STATION)
	wifi.sta.config(ssid, pass)
	wifi.sta.connect()
end

test_count = 0
tmr.alarm(1, 100, 1, testConnection)	-- 0.1s
