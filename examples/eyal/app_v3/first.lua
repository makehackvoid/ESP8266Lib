time_First = tmr.now()
time_dofile = time_dofile + (time_First-start_dofile)
local mLog = mLog
local function Log (...) if print_log then mLog ("first", unpack(arg)) end end
local function Trace(n, new) mTrace(6, n, new) end Trace (0, true)
used ()
out_bleep()

local function have_first()
	time_First = tmr.now() - time_First
	do_file ("save")
end

if "mqtt" == save_proto then
	local mqtt_client = string.gsub(string.lower(wifi.sta.getmac()),":","-")
	local topic = ("stats/%s/message"):format(mqtt_client)
	local mqttClient = mqtt.Client(mqtt_client, 2)
	mqttClient:on ("offline", function(client)
		Log("mqtt offline")
		if not runCount then
			Log("mqtt first failed")
			runCount = 1
		end
		Trace (1)
		have_first()
	end)
	mqttClient:on ("connect", function(client)
		Log("mqtt connect")
		client:subscribe(topic, 0, function(client)
			Log ("subscribed")
		end)
	end)
	mqttClient:on ("message", function(client, topic, data)
		Log ("mqtt message")
		if data ~= nil then
			Trace (2)
			-- expecting 'clientID runCount times=...'
			runCount, n = string.gsub (data, " +[^ ]+ +(%d+) .*", "%1")
		else
			Trace (3)
			runCount = 0	-- should not happen
		end
		runCount = runCount + 1
		client:close()
		mqtt_client  = nil
		have_first()
	end)
	mqttClient:connect (saveServer, savePort, 0)
elseif "tcp" == save_proto or "udp" == save_proto then
	local conn = net.createConnection(net.TCP, 0)

	conn:on("disconnection", function(client, data)
		Log ("disconnected")

		if runCount then
			Log ("unexpected disconnection, runCount=%d", runCount)
			Trace (5)	-- should not happen
		else
			Log ("connection failed")
			Trace (4)
			runCount = 1
		end

		conn  = nil
		have_first()
	end)

	conn:on("receive", function(client, data)
		Log ("received '%s'", data)
		Trace (9)

		runCount = data + 1

		tmr.wdclr()
		client:close()	-- not expecting "disconnection"
		conn  = nil
		Trace (10)
		have_first()
	end)

	conn:on("sent", function(client)
		Log ("sent")
		Trace (8)
	end)

	conn:on("connection", function(client)
		Log ("connected")
		Trace (7)

		tmr.wdclr()
		client:send (("last/%s"):format(clientID))	-- request last runCount
	end)

	Trace (6)
	tmr.wdclr()
	conn:connect(savePort, saveServer)
else
	Log ("unknown save_proto '%s'", save_proto)
	runCount = 1
	have_first()
end

