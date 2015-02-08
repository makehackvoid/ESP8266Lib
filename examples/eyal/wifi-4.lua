user, pass = "user", "password";
mqtt_host, mqtt_port = "192.168.1.2", 1883;
topic = "eyal/esp-07";

-- ESP-01 GPIO Mapping
gpio0 = 3;	-- clixx 'i'
gpio2 = 4;	-- clixx 'o'

fake_it = false;		-- do not read the ds18b20
pub_rate = 5;		-- seconds
sleep = 0;		-- 1 for yes

function dbg (msg)
	if true then	-- enable debug messages
		print (msg);
	end
end

function memUsed ()
	k,b = collectgarbage ("count");
	return (k*1024) + ((nil == b) and 0 or b);
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

if fake_it then
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

dbg ("mqtt.Client");
	m = mqtt.Client("esp-07", 600);
-- fw 20150226 restarts before getting here --
dbg ("m:connect");
	m:connect (mqtt_host, mqtt_port, 0, connected);

	dbg ("exit publishData");
end

function connected (conn)
	collectgarbage();
	dbg ("connected");

	tmr.alarm (1, pub_rate*1000, 1-sleep, publish);
	dbg ("exit connected");
end

function publish ()
	dbg ("publish");

	msg = readTemperature () .. "dC " .. memUsed ();
	m:publish (topic, msg, 0, 1,
		function (conn)
			if (1 == sleep) then
				main_3 ();
			end
		end);

	dbg ("exit publish");
end

function ds18b20_init ()
	dbg ("ds18b20_init");
	if fake_it then
		dC = 0;
		ds18b20_ndevs = 1;
	else
		collectgarbage();
		dbg ("used memory before=" .. memUsed ());
		ds18b20 = require("ds18b20");
-- fw 20150227 fails "not enough memory" before getting here --
		dbg ("used memory after =" .. memUsed ());

		ds18b20.setup(gpio2);
		ds18b20_ndevs = table.getn(ds18b20.addrs());
		dbg ("Found " .. ds18b20_ndevs .. " ds18b20 devices");
		collectgarbage();
	end

	dbg ("exit ds18b20_init");
end

function main_2 ()	-- have a connection, now read and pulish
	collectgarbage();
	dbg ("main_2");

			-- read the ds18b20

	if ds18b20_ndevs > 0 then
		publishData();
	else
		dbg ("no devices found");
		main_3 ();
	end

	dbg ("exit main_2");
end

function main_3()
	collectgarbage();
	dbg ("main_3");

	if (1 == sleep) then
		dbg ("will dsleep")
		node.dsleep (5*1000000);
	else
		-- do nothing
	end

	dbg ("exit main_3");
end

dbg ("main");

ds18b20_init ()
main_1 ();

dbg ("exit main");
