time_start = tmr.now() / 1000000;
--collectgarbage()

function log (message, force)
	if print_log or force then
		print ((tmr.now()/1000000) .. " " .. message);
	end
end

function used (title)
	log (title .. " used " .. collectgarbage("count")*1024)
end

used ("config")

function doSleep ()
	if sleep_time > 0 then
		---log ("dsleep " .. sleep_time/1000000 .. "s")
		node.dsleep (sleep_time);
	else
		log ("not sleeping")
		runCount = nil	-- in case we rerun in same env
--		collectgarbage()
	end
end

local function config()
	local gpio0  = 3;	-- ESP-01, clixx o
	local gpio2  = 4;	-- ESP-01, clixx i
	--local gpio4  = 2;
	--local gpio5  = 1;
	--local gpio14 = 5;
	--local gpio12 = 6;
	--local gpio13 = 7;

-- which is the magic pin?
	if nil == magic_pin then
		magic_pin = -1;	--gpio5;		-- '-1' to disable the magic
	end
	if magic_pin >= 0 then
		gpio.mode (magic_pin, gpio.INPUT);
		if 0 == gpio.read (magic_pin) then
			print ("config: aborting by magic");
			abort = true
			return
		end
	end

-- which pins is the i2c attached to?
	if nil == i2c_SDA then
		i2c_SDA, i2c_SCL = gpio2, gpio0;	-- '-1' to disable i2c
	end

-- which pin is the one-wire attached to?
	if nil == ow_pin then
		ow_pin = -1;	--gpio4;		-- '-1' to disable ow
	end

-- your access point details
	if nil == ssid then
		ssid, passphrase = "ssid", "passphrase";
	end

-- MQTT setup
	if nil == MQTT_clientid then
		MQTT_clientid = "esp01";
	end
	if nil == MQTT_keepalive then
		MQTT_keepalive = 30;
	end
	if nil == MQTT_topic then
		MQTT_topic = "testing/esp01";
	end
	if nil == Broker_Address then
		Broker_Address = "192.168.3.4";
	end
	if nil == Broker_Port then
		Broker_Port = 1883;
	end

-- if you want to set up the WiFi then set
--	use_old_WiFi_setup = false
-- before starting a run with 'dofile("init.lc")'
	if nil == use_old_WiFi_setup then
		use_old_WiFi_setup = true;	-- default: already have WiFi set up
	end

-- if you want to restart counting then set the new staring value
-- before starting a run with 'dofile("init.lc")'
--	runCount = nnn

-- the previous runCount can be fetched from the MQTT broker. however it can be
-- store on the ds3231 in the Alarm2 3 bytes. This is better and the default.
	if nil == abuseAlarm then
		abuseAlarm = true
	end

-- how to execute lua programs?
-- if they were compiled then use ".lc", otherwise use ".lua"
	if nil == lua_type then
		lua_type = ".lc";
	end

-- do we want 'log()' calls to actually print messages?
	if nil == print_log then
		print_log = true;	-- 'false' to disable printing of log messages
	end

-- how long we sleep between runs?
	if nil == sleep_time then
		sleep_time = 0;		--3*1000000;		-- 0 to disable dsleep
	end

-- DEBUG: do we want to enable WiFi, to allow publishing to the MQTT broker?
	if nil == do_wifi then
		do_wifi = true;		-- 'false' to disable WiFi access
	end

-- DEBUG: do we want to publish to the MQTT broker?
	if nil == do_MQTT then
		do_MQTT = true;		-- 'false' to disable MQTT access
	end
end

config()
