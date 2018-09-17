local mLog = mLog
local function Log (...) if print_log then mLog ("save-mqtt", unpack(arg)) end end
local function Trace(n, new) mTrace(8, n, new) end Trace (0, true)
used ()
out_bleep()

local function domqtt()
	if nil == mqtt then
		Log ("no mqtt module")
		message = nil
		Trace (7)
		doSleep()
		return false
	end

	local mqtt_client = string.gsub(string.lower(sta.getmac()),":","-")
	local topic = ("stats/%s/message"):format(mqtt_client)
	local mqttClient = mqtt.Client(mqtt_client, 2)
	if nil == mqttClient then
		Log ("mqtt.Client failed")
		message = nil
		Trace (6)
		doSleep()
		return false
	end

	mqttClient:connect (saveServer, savePort, 0,
		function(client)		-- connected
			Trace (1)
			mqttClient:publish (topic, message, 0, 1, function (client)
				Trace (2)
				message = nil
				client:close()
				mqttClient = nil
				Trace (3)
				doSleep()
			end)
		end,
		function(client, reason)	-- failed
--[[
reson:
CONN_FAIL_SERVER_NOT_FOUND	-5 There is no broker listening at the specified IP Address and Port
CONN_FAIL_NOT_A_CONNACK_MSG	-4 The response from the broker was not a CONNACK as required by the protocol
CONN_FAIL_DNS			-3 DNS Lookup failed
CONN_FAIL_TIMEOUT_RECEIVING	-2 Timeout waiting for a CONNACK from the broker
CONN_FAIL_TIMEOUT_SENDING	-1 Timeout trying to send the Connect message
CONNACK_ACCEPTED		 0 No errors. Note: This will not trigger a failure callback.
CONNACK_REFUSED_PROTOCOL_VER	 1 The broker is not a 3.1.1 MQTT broker.
CONNACK_REFUSED_ID_REJECTED	 2 The specified ClientID was rejected by the broker.
CONNACK_REFUSED_SERVER_UNAVAILABLE 3 The server is unavailable.
CONNACK_REFUSED_BAD_USER_OR_PASS 4 The broker refused the specified username or password.
CONNACK_REFUSED_NOT_AUTHORIZED	 5 The username is not authorized.
--]]
			Trace (4)
			Log ("mqtt:connect failed %d", reason)
			Log ("message='%s'", message)
			message = nil
			client:close()
			mqttClient = nil
			Trace (5)
			doSleep()
		end)
end

domqtt()

