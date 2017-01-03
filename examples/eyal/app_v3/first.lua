time_First = tmr.now()
time_dofile = time_dofile + (time_First-start_dofile)
local mLog = mLog
local function Log (...) if print_log then mLog ("first", unpack(arg)) end end
local function Trace(n) mTrace(6, n) end Trace (0)
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
			-- expecting 'clientID runCount times=...'
			runCount, n = string.gsub (data, " +[^ ]+ +(%d+) .*", "%1")
		else
			runCount = 0	-- should not happen
		end
		runCount = runCount + 1
		client:close()
		have_first()
	end)
	mqttClient:connect (saveServer, savePort, 0)
elseif "tcp" == save_proto or "udp" == save_proto then
	local conn = net.createConnection(net.TCP, 0)

	conn:on("disconnection", function(conn, data)
		Log ("disconnected")

		if not runCount then
			Log ("connection failed")
			runCount = 1
		end

		have_first()
	end)

	conn:on("receive", function(conn, data)
		Log ("received '%s'", data)

		runCount = data + 1

		tmr.wdclr()
		conn:close()
	end)

	conn:on("sent", function(conn)
		Log ("sent")
	end)

	conn:on("connection", function(conn)
		Log ("connected")

		tmr.wdclr()
		conn:send (("last/%s"):format(clientID))	-- request last runCount
	end)

	tmr.wdclr()
	conn:connect(savePort, saveServer)
else
	Log ("unknown save_proto '%s'", save_proto)
	runCount = 1
	have_first()
end

