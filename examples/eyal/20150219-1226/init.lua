time_start = tmr.now() / 1000000;

-- set the following to your specific environment:
ssid, passphrase = "SSID", "passphrase";
Broker_Address, Broker_Port = "192.168.2.7", 1883;
MQTT_user, MQTT_timeout = "my-esp", 30;
MQTT_topic = "testing/temp";

local gpio0 = 3;
local gpio2 = 4;
local gpio4 = 2;
local gpio5 = 1;

-- what pin the ds18b20 is attached to. 'nil' will not read it and report the run number instead.
ds18b20_pin = gpio4;

-- whis is the magic pin. If set, and pulled LOW, then program will stop looping.
magic_pin   = gpio5;

-- do we want 'log()' calls to actually print anything? Set to 'false' when running standalone.
print_log = true;


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

	-- we do this very early to avoid "not enough memory" issues
	dofile ("readTemp.lc");

	dofile ("doWiFi.lc");

	log ("main end");
end

main ()
