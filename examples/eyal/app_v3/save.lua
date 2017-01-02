local tmr = tmr
local time_Save = done_file (tmr.now())
local mLog = mLog
local sta = wifi.sta
local function Log (...) if print_log then mLog ("save", unpack(arg)) end end
local function Trace(n) mTrace(7, n) end Trace (0)
used ()
out_bleep()

local function format_message()
	local failSoft, failHard, failRead, timeLast, timeTotal, timeLeft
		= 0, 0, 0, 0, 0, 0
	if have_rtc_mem then
		failSoft  = rtcmem.read32(rtca_failSoft)	-- count
		failHard  = rtcmem.read32(rtca_failHard)	-- count
		failRead  = rtcmem.read32(rtca_failRead)	-- count
		timeLast  = rtcmem.read32(rtca_lastTime)	-- us
		timeTotal = rtcmem.read32(rtca_totalTime)	-- ms
		timeLeft  = rtcmem.read32(rtca_timeLeft)	-- us
	end

	local times = ""
	if send_times then
		time_Save = tmr.now() - time_Save
		times = 
(" times=L%.3f,l%.3f,T%d,s%.3f,u%.3f,r%.3f,w%.3f,F%.3f,S%.3f,d%.3f,t%.3f"):format(
			timeLast / 1000000,	-- from prev cycle
			timeLeft / 1000000,	-- from prev cycle
			timeTotal / 1000,	-- from prev cycle
			time_start / 1000000,
			time_setup / 1000000,
			time_read / 1000000,
			time_wifi / 1000000,
			time_First / 1000000,
			time_Save / 1000000,
			time_dofile / 1000000,
			(tmr.now() - time_start) / 1000000)
		if nil ~= rtc_start_s then
			times = ("%s,R%d.%06d"):format(
				times,
				rtc_start_s, rtc_start_u)
		end
		local reasons = ""
		if send_reason then
--[[
struct rst_info* ri = system_get_rst_info();
struct rst_info {
	uint32 reason; // enum rst_reason
	uint32 exccause;
	uint32 epc1;  // the address that error occurred
	uint32 epc2;
	uint32 epc3;
	uint32 excvaddr;
	uint32 depc;
};
enum rst_reason {
	REASON_DEFAULT_RST      = 0, // normal startup by power on
	REASON_WDT_RST	        = 1, // hardware watch dog reset 
	// exception reset, GPIO status won't change 
	REASON_EXCEPTION_RST    = 2, 
	// software watch dog reset, GPIO status won't change 
	REASON_SOFT_WDT_RST     = 3, 
	// software restart, system_restart , GPIO status won't change
	REASON_SOFT_RESTART     = 4, 
	REASON_DEEP_SLEEP_AWAKE = 5, // wake up from deep-sleep 
	REASON_EXT_SYS_RST      = 6, // external system reset
};
code = rtc_get_reset_reason();
reason = ri.reason;
--]]
			local code, reason = node.bootreason()
			times = ("%s,b%d/%d"):format(
				times,
				code, reason)
		end
	end

	local stats = ""
	if send_stats then
		stats = (" stats=fs%d,fh%d,fr%d,t%u"):format(
			failSoft,
			failHard,
			failRead,
			(last_trace or 99999999))
		if send_mem then
			local mu = mem_used or 0
			local mh = mem_heap or 0
			stats = ("%s,mu%d,mh%d"):format(
				stats,
				mu,
				mh)
		end
	end

	local radio = ""
	if send_radio then
		radio = (" radio=s%d"):format(
			-sta.getrssi())
	end

	if adc_factor then	-- no vdd with adc anymore
		vbat = adc.read(0)*adc_factor
		vdd33 = 3300			-- dummy
	else
		vbat = 0			-- dummy
		vdd33 = adc.readvdd33()*vdd_factor
	end

	local noTemp = 0			-- or 85?
	local tCs
	if 0 == #temp then
		tCs = ("%.4f"):format(noTemp)
	else
		tCs = ""
		local tSep = ""
		for n = 1,#temp do
			tCs = ("%s%s%.4f"):format(tCs, tSep, (temp[n] or noTemp))
			tSep = ","
		end
	end

	if not weather then weather = "" end
	if "mqtt" == save_proto then
		command = ''
	else
		command = 'store '
	end
	return ("%s%s %3d%s%s%s%s adc=%.3f vdd=%.3f %s%s"):format(
		command,
		clientID,
		runCount,
		times,
		stats,
		radio,
		weather,
		vbat / 1000,
		vdd33 / 1000,
		tCs,
		save_eom)
end

if have_rtc_mem then
	rtcmem.write32(rtca_runCount, runCount)
end

local msg = format_message()
format_message = nil

if not do_Save then
	print_log = true
	Log (msg)
	msg = nil
	doSleep()
elseif "udp" == save_proto then
	local conn = net.createConnection(net.UDP, 0)

	conn:on("sent", function(conn)
		grace_time = tmr.now() + udp_grace_ms*1000
		Log ("sent")
		msg = nil

		conn:close()
		doSleep()
	end)

	Log("connecting to %s:%d", saveServer, savePort)
	conn:connect(savePort, saveServer)

	Log ("send '%s'", msg)
	conn:send (msg)
--[[
elseif "tcp" == save_proto then
	local conn = net.createConnection(net.TCP, 0)

	conn:on("disconnection", function(conn)
		Log ("disconnected")

		doSleep()
	end)

	conn:on("sent", function(conn)
		Log ("sent")
		msg = nil

		conn:close()
	end)

	conn:on("connection", function(conn)
		Log ("connected")

		Log ("send '%s'", msg)
		conn:send (msg)
	end)

	Log("connecting to %s:%d", saveServer, savePort)
	conn:connect(savePort, saveServer)
--]]
elseif "mqtt" == save_proto then
	local mqtt_host = mqtt_host or saveServer
	local mqtt_port = mqtt_port or 1883
	local mqtt_client = string.gsub(string.lower(sta.getmac()),":","-")
	local topic = ("stats/%s/message"):format(mqtt_client)
	local mqttClient = mqtt.Client(mqtt_client, 2)
	mqttClient:connect (mqtt_host, mqtt_port, 0,
	function(client)
		mqttClient:publish (topic, msg, 0, 1, function (client)
			msg = nil
			client:close()
			doSleep()
		end)
	end,
	function(client, reason)
--[[
mqtt.CONN_FAIL_SERVER_NOT_FOUND		-5	There is no broker listening at the specified IP Address and Port
mqtt.CONN_FAIL_NOT_A_CONNACK_MSG	-4	The response from the broker was not a CONNACK as required by the protocol
mqtt.CONN_FAIL_DNS			-3	DNS Lookup failed
mqtt.CONN_FAIL_TIMEOUT_RECEIVING	-2	Timeout waiting for a CONNACK from the broker
mqtt.CONN_FAIL_TIMEOUT_SENDING		-1	Timeout trying to send the Connect message
mqtt.CONNACK_ACCEPTED			0	No errors. Note: This will not trigger a failure callback.
mqtt.CONNACK_REFUSED_PROTOCOL_VER	1	The broker is not a 3.1.1 MQTT broker.
mqtt.CONNACK_REFUSED_ID_REJECTED	2	The specified ClientID was rejected by the broker. (See mqtt.Client())
mqtt.CONNACK_REFUSED_SERVER_UNAVAILABLE	3	The server is unavailable.
mqtt.CONNACK_REFUSED_BAD_USER_OR_PASS	4	The broker refused the specified username or password.
mqtt.CONNACK_REFUSED_NOT_AUTHORIZED	5	The username is not authorized.
--]]
		Log("mqtt:connect failed %d", reason)
		Log ("msg='%s'", msg)
		msg = nil
		doSleep()
	end)
else
	print_log = true
	Log("unknown save_proto='%s'", save_proto)
	Log ("msg='%s'", msg)
	msg = nil
	doSleep()
end
