time_start = tmr.now() / 1000000;
local gpio0 = 3;
local gpio2 = 4;
local gpio4 = 2;
local gpio5 = 1;


----------------------------------
----- settings section start -----
----------------------------------

-- your access point details
ssid, passphrase = "ssid", "password";

-- your MQTT broker details
Broker_Address, Broker_Port = "192.168.2.7", 1883;

-- if you want to set up the WiFi then set
--	use_old_WiFi_setup = false
-- before starting a run with 'dofile("init.lua")'
if nil == use_old_WiFi_setup then
	use_old_WiFi_setup = true;	-- default: already have WiFi set up
end

-- if you want to start counting from 1 again then set
--	resetRunCount = true
-- before starting a run with 'dofile("init.lua")'
if nil == resetRunCount then
	resetRunCount = false;		-- default: continue counting
end

-- you can leave these two lines as is or change to your liking.
MQTT_user, MQTT_timeout = "my-esp", 30;
MQTT_topic = "testing/temp";

-- how to execute lua programs?
-- if they were compiled then use ".lc", otherwise use ".lua"
lua_type = ".lc";

-- what pin is the ds18b20 attached to?
-- if disabled then use the run number as a fake reading
ds18b20_pin = gpio4;		-- 'nil' to disable

-- which is the magic pin?
magic_pin   = gpio5;		-- 'nil' will disable the magic

-- do we want 'log()' calls to actually print messages?
print_log = false;		-- 'false' to disable printing of log messages

-- do we want to enable WiFi, to allow publishing to the MQTT broker?
do_wifi = true;			-- 'false' to disable WiFi access

-- do we want to publish to the MQTT broker?
do_MQTT = true;			-- 'false' to disable MQTT access

-- how long we sleep between runs?
sleep_time = 60*1000000;		-- 60 seconds

--------------------------------
----- settings section end -----
--------------------------------

function log (message, force)
	if print_log or force then
		print ((tmr.now()/1000000) .. ": " .. message);
	end
end

function main()
	log ("main start");

	if nil ~= magic_pin then
		gpio.mode (magic_pin, gpio.INPUT);
		if 0 == gpio.read (magic_pin) then
			print ("aborting by magic");
			return
		end
	end

	if nil == ds18b20_pin then
		log ("not reading ds18b20");
		temp = nil;
	else
		-- we do this very early to avoid "not enough memory" issues
		dofile ("readTemp"..lua_type);
	end

	if do_wifi then
		dofile ("doWiFi"..lua_type);
	else
		log ("sleep " .. sleep_time/1000000 .. "s")
		node.dsleep (sleep_time);
	end

	log ("main end");
end

main ()
