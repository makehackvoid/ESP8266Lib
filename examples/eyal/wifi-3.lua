-- This example works for me with "fake_it=true".
-- It fails otherwise, either with "not enough memory" when loading the ds18b20 module (fw 20150127)
-- or by failing to connect to the broker (fw 20150126).
-- test 1

user, pass = "user", "pass";
mqtt_host, mqtt_port = "192.168.2.7", 1883;

-- ESP-01 GPIO Mapping
gpio0 = 3;	-- clixx 'i'
gpio2 = 4;	-- clixx 'o'

fake_it = false;	-- read the ds18b20 or fake it?
pub_rate = 5;		-- seconds

function dbg (msg)
	if true then	-- enable debug messages
		print (msg);
	end
end

function waitForConnection ()
	collectgarbage();
	dbg ("waitForConnection");

	nwait = nwait + 1;
	ip = wifi.sta.getip();
	if nil ~= ip then
		tmr.stop (1);
		dbg ("Node MAC: " .. wifi.sta.getmac());
		dbg ("Node  IP: " .. ip .. " after " .. (nwait*100) .. "us");
		main_2();
	else
		dbg ("no IP yet... " .. nwait);
	end
	dbg ("exit waitForConnection");
end

function main_1 ()
	collectgarbage();
	dbg ("main_1");

	ip = wifi.sta.getip();
	if nil == ip then
		wifi.setmode(wifi.STATION);
		wifi.sta.config(user, pass);
		wifi.sta.connect();
		dbg ("Connecting to '" .. user .. "'");

		nwait = 0;
		tmr.alarm (1, 100, 1, waitForConnection);
	else
		main_2();
	end
	dbg ("exit main_1");
end

function readTemperature()
	collectgarbage();
	dbg ("readTemperature");

if nil == ds18b20 then
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

	dbg ("exit readTemperature (" .. dC .. ")");
	return (dC);
end

function publishData()
	collectgarbage();
	dbg ("publishData");

	m = mqtt.Client("esp-07", 600);
	m:connect (mqtt_host, mqtt_port, 0, connected);
	dbg ("exit publishData");
end

function connected (conn)
	collectgarbage();
	dbg ("connected");

	tmr.alarm (1, pub_rate*1000, 1, publish);
	dbg ("exit connected");
end

function publish ()
	dbg ("publish");

	m:publish ("stats/temperature/esp-07", readTemperature (), 0, 1,
		function (conn)
		end);

	main_3 ();

	dbg ("exit publish");
end


function main_2 ()	-- have a connection, now read and pulish
	collectgarbage();
	dbg ("main_2");

if fake_it then
	dC = 0;
	ndevs = 1;
else			-- read the ds18b20
dbg ("used memory=" .. collectgarbage ("count") .. "K");
dbg ("before require");
	ds18b20 = require("ds18b20");
dbg ("after require");
	collectgarbage();

	ds18b20.setup(gpio2);
	ndevs = table.getn(ds18b20.addrs());
	dbg ("Found " .. ndevs .. " ds18b20 devices");
end
	if ndevs > 0 then
		publishData();
	else
		main_3 ();
	end
	dbg ("exit main_2");
end

function main_3()
	collectgarbage();
	dbg ("main_3");

-- do nothing

	dbg ("exit main_3");
end

dbg ("main");
main_1 ();
dbg ("exit main");
