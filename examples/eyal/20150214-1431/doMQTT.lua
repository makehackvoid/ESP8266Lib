m = mqtt.Client("clientid", 2)	-- , "user", "password")

m:on("offline", function(conn)
	print ("offline at " .. tmr.now())
	node.dsleep(2*1000000)		-- 2s
end)

print ("m:connect")
m:connect(Broker_IP_Address, Broker_Port, 0, function(conn)
	print("connected at " .. tmr.now())
--	dofile ("readTemp.lc");
	print("publish temperature "..temp.."'C")
	m:publish("testing/temp", (runCount..": "..temp), 0, 1, function(conn)
		print ("published at " .. tmr.now())
		m:close();
	end)
end)
