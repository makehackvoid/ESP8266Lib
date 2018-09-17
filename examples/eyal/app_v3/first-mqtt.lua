time_First = done_file (tmr.now())
local mLog = mLog
local function Log (...) if print_log then mLog ("first", unpack(arg)) end end
local function Trace(n, new) mTrace(0x0B, n, new) end Trace (0, true)
used ()
out_bleep()

local timeout = tmr.create()
local clientName
local mqttClient

local function have_first(count)
	runCount = count
	time_First = tmr.now() - time_First
	timeout:unregister()
	clientName = nil
	if mqttClient then
		mqttClient:close()
		mqttClient = nil
	end
	do_file ("save")
end

local function first_mqtt()
	if nil == mqtt then
		Trace (1)
		Log ("no mqtt module")
		have_first(1)
		return false
	end

	clientName = string.gsub(string.lower(wifi.sta.getmac()),":","-")
	mqttClient = mqtt.Client(clientName, 2)
	if nil == mqttClient then
		Trace (2)
		Log ("mqtt.Client failed")
		have_first(1)
		return false
	end

	mqttClient:on ("offline", function(client)
		Log("mqtt offline")
		if not runCount then
			Log("mqtt first failed")
			runCount = 1
		end
		Trace (3)
		have_first(runCount)
	end)
	mqttClient:on ("connect", function(client)
		Log("mqtt connect")
		local topic = ("stats/%s/message"):format(clientName)
		client:subscribe(topic, 0, function(client)
			Log ("subscribed")
		end)
	end)
	mqttClient:on ("message", function(client, topic, data)
		Log ("mqtt message")
		if data ~= nil then
			Trace (4)
			-- expecting 'clientID runCount times=...'
			runCount, n = string.gsub (data, " +[^ ]+ +(%d+) .*", "%1")
		else
			Trace (5)
			runCount = 0	-- should not happen
		end
		have_first(runCount + 1)
	end)
	timeout:alarm(first_timeout, tmr.ALARM_SINGLE, function()
		Log("exchange timeout")
		Trace (6)
		have_first(1)
	end)
	mqttClient:connect (saveServer, savePort, 0)
end

first_mqtt()

