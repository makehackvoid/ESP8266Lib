local user, pass = "user", "password";
local mqtt_host, mqtt_port = "192.168.1.2", 1883;
local topic = "eyal/esp-07";

-- local tmr = tmr;
-- local table = table;

-- ESP-01 GPIO Mapping
local gpio0 = 3;		-- clixx 'i'
local gpio2 = 4;		-- clixx 'o'

local read_ds18b20 = false;	-- read the ds18b20 or fake it?
local pub_rate = 5;		-- publish every so many seconds
local sleep = 1;		-- 1 to dsleep, 0 to not

local debugging = true;		-- print debug messages
local tracing = true;		-- print all function enter/exit

local function dbg (msg)
	if debugging then
		print (msg);
	end
end

local function Enter (func)
	if tracing then
		dbg ("enter " .. func);
	end
end

local function Exit (func)
	if tracing then
		dbg ("exit  " .. func);
	end
end

local function showMem (title)
	collectgarbage();

	local k, b, h;

	k, b = collectgarbage ("count");
	k = k*1024 + ((nil == b) and 0 or b);
	h = node.heap();
	print (title .. ": memory used " .. k .. " heap " .. h .. " all " .. (k+h));
end

local ds18b20;
local dC;

local function ds18b20_init ()
	Enter ("ds18b20_init");

	if read_ds18b20 then
		collectgarbage();
showMem ("before");
		ds18b20 = require("ds18b20");
-- fw 2015012[67] fail "not enough memory" before getting here --
showMem ("after ");

		ds18b20.setup(gpio2);
		ds18b20_ndevs = table.getn(ds18b20.addrs());
		dbg ("Found " .. ds18b20_ndevs .. " ds18b20 devices");
		collectgarbage();
	else
		dbg ("faking a ds18b20");
		dC = 0;
		ds18b20_ndevs = 1;
	end

	Exit ("ds18b20_init");
end

local function readTemperature()
	collectgarbage();
	Enter ("readTemperature");

	if read_ds18b20 then
		dC = dC + 1;
	else
		while true do
			dC = ds18b20.read();
			if dC ~= nil and dC ~= 85 then
				break
			end
			dbg ("rereading");
			tmr.delay(100000);	-- 0.1s
		end
	end

	Exit ("readTemperature (" .. dC .. ")");
	return (dC);
end

local function jobDone()
	collectgarbage();
	Enter ("jobDone");

	if (1 == sleep) then
		dbg ("will dsleep")
		-- node.dsleep (5*1000000);
	else
		-- do nothing
	end

	Exit ("jobDone");
end

local mqttClient;

local function mqtt_publish ()
	Enter ("mqtt_publish");

	local msg = readTemperature () .. "dC " .. memUsed ();
	dbg ("mqttClient:publish ('" .. msg .. "')");
	mqttClient:publish (topic, msg, 0, 1,
		function (conn)
			dbg ("published '" .. msg .. "'");
			if (1 == sleep) then
				jobDone ();
			end
		end);

	Exit ("mqtt_publish");
end

local function mqtt_connected (conn)
	collectgarbage();
	Enter ("mqtt_connected");

	tmr.alarm (1, pub_rate*1000, 1-sleep, mqtt_publish);

	Exit ("mqtt_connected");
end

local function publishData()
	collectgarbage();
	Enter ("publishData");

dbg ("mqtt.Client");
showMem ("before");
	mqttClient = mqtt.Client("esp-07", 600);
-- fw 20150126 restarts before getting here (when faking it) --
showMem ("after ");

	mqttClient:connect (mqtt_host, mqtt_port, 0, mqtt_connected);

	Exit ("publishData");
end

local nwait = 0;

local function haveConnection ()	-- have a connection, now read and pulish
	collectgarbage();
	Enter ("haveConnection");

	dbg ("Node MAC: " .. wifi.sta.getmac());
	dbg ("Node  IP: " .. wifi.sta.getip() .. " after " .. (nwait*100) .. "us");

	ds18b20_init ();
	if ds18b20_ndevs > 0 then
		publishData();
	else
		dbg ("no devices found");
		jobDone ();
	end

	Exit ("haveConnection");
end

local function waitingForConnection ()
	collectgarbage();
	Enter ("waitingForConnection");

	nwait = nwait + 1;
	local ip = wifi.sta.getip();
	if nil ~= ip then
		tmr.stop (1);
		haveConnection();
	else
		dbg ("waiting for IP... " .. nwait);
	end

	Exit ("waitingForConnection");
end

local function setupConnection()
	Enter ("setupConnection");

	local ip = wifi.sta.getip();
	if nil == ip then
		wifi.setmode(wifi.STATION);
		wifi.sta.config(user, pass);
		wifi.sta.connect();
		dbg ("Connecting to '" .. user .. "'");

		tmr.alarm (1, 100, 1, waitingForConnection);
	else
		haveConnection ();
	end

	Exit ("setupConnection");
end

Enter ("main");

showMem ("main");
setupConnection ();

Exit ("main");
