--collectgarbage()
used ("doMQTT")

local time_mqtt = tmr.now()

local function doPublish (client)
--	log ("doMQTT run " .. runCount)

	if nil == temp then
		temp = runCount
		timestamp = "00000000000000"
		time_read = 0
	end

	time_now = tmr.now()
	time_mqtt = (time_now - time_mqtt) / 1000000
	local msg = string.format (
		"%4d %s times=%.6g,%.6g,%.6g,%.6g,%.6g vdd=%-5.3g %s",
		runCount,
		timestamp,
		time_start,
		time_read,
		time_wifi,
		time_mqtt,
		(time_now - time_start) / 1000000,
		node.readvdd33() / 1000,
		temp)

	log ("doMQTT publish '" .. msg .. "'")
	client:publish (MQTT_topic, msg, 0, 1, function(client)
		log ("published")
		client:close()
	end)
end

local function onOffline(client)
	log ("doMQTT offline")

	doSleep ()
--	collectgarbage()
	used ("doMQTT end")
end

local function onMessage(client, topic, data)
	log ("doMQTT message topic='" .. topic .. "'")
	if data ~= nil then
		-- print (data)
		runCount, n = string.gsub (data, " *(%d+) .*", "%1")
		if n < 1 then
			runCount = 0
		end
	else
		runCount = 0
	end
	runCount = runCount + 1

	doPublish (client)
end

local function doConnect (client)
	log ("doMQTT connected")

	if nil == runCount then
		client:subscribe(MQTT_topic, 0, function(client)
			log ("doMQTT subscribed")
		end)
	else
		doPublish (client)
	end
end

--local function doMQTT()
	if do_MQTT then
		local client = mqtt.Client(MQTT_clientid, MQTT_keepalive)
		client:on ("offline", onOffline)
		client:on ("message", onMessage)

		log ("client:connect("..Broker_Address..","..Broker_Port..",0)")
		client:connect (Broker_Address, Broker_Port, 0, doConnect)
	else
		log ("doMQTT not doing MQTT")
	end
--end

--tmr.stop(1)
--tmr.alarm(1, 10, 0, doMQTT)
--collectgarbage()

---log ("doMQTT end")
