m = mqtt.Client(MQTT_user, MQTT_timeout)	--  or add (...,..., "user", "password")

m:on ("offline", function(conn)
	log ("offline")
	node.dsleep(6*1000000)		-- or 60s?
end)

local function doPublish ()
	log ("run " .. runCount)

--	dofile ("readTemp.lc");
	if nil == temp then
		temp = runCount
	end

	local msg = string.format ("%4d times=%.6g,%.6g,%.6g vdd=%-5.3g %s",
		runCount, time_start, time_read, tmr.now()/1000000,
		node.readvdd33()/1000, temp)

	log ("publish '" .. msg .. "'")
	m:publish (MQTT_topic, msg, 0, 1, function(conn)
		log ("published")
		m:close();
	end)
end

m:on ("message", function (conn, t, d)
	-- print (t..":")
	if d ~= nil then
		-- print (d)
		runCount, n = string.gsub (d, " *(%d+) .*", "%1")
		if n < 1 then
			runCount = 0
		end
	else
		runCount = 0
	end
	runCount = runCount + 1

	doPublish ();
end)

log ("m:connect")
m:connect(Broker_Address, Broker_Port, 0, function(conn)
	log ("connected")

	if resetRunCount then
		runCount = 1;
		doPublish ();
	else
		m:subscribe(MQTT_topic, 0, function(conn)
			log ("subscribed")
		end)
	end
end)
