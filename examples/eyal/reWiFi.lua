-- Testing: set up Wifi connection then restart

local gpio0 = 3;
local gpio2 = 4;
local gpio4 = 2;
local gpio5 = 1;

----------------------------------
----- settings section start -----
----------------------------------

-- your access point details
ssid, passphrase = "ssid", "passphrase";

-- if you want to set up the WiFi then set
--	use_old_WiFi_setup = false
-- before starting a run with 'dofile("init.lua")'
if nil == use_old_WiFi_setup then
	use_old_WiFi_setup = true;	-- default: already have WiFi set up
end

-- which is the magic pin?
magic_pin   = gpio5;		-- 'nil' will disable the magic

-- do we want 'log()' calls to actually print messages?
print_log = false;		-- 'false' to disable printing of log messages

-- how long we sleep between runs?
sleep_time = 3*1000000;		--3 seconds

--------------------------------
----- settings section end -----
--------------------------------

local function log (message)
	if print_log then
		print ((tmr.now()/1000000) .. ": " .. message);
	end
end

local function testConnection()
	test_count = test_count + 1;
	if nil == wifi.sta.getip() then
		if 0 == test_count % 10 then
			log ("IP unavailable after " .. test_count .. " tries");
		end
	else
		tmr.stop(1);
		log ("IP   available after " .. test_count .. " tries: "
			.. wifi.sta.getip());
		node.dsleep (sleep_time);
	end 
end

local function main ()
	log ("main start");

	if nil ~= magic_pin then
		gpio.mode (magic_pin, gpio.INPUT);
		if 0 == gpio.read (magic_pin) then
			print ("aborting by magic");
			return;
		end
	end

	local test_count = 0;

	if nil == wifi.sta.getip() then
		if use_old_WiFi_setup then
			log ("using old WiFi setup");
		elseif nil == ssid or nil == passphrase then
			print ("missing ssid/pass");
			return;
		else
			log ("Setting up WIFI...");
			wifi.setmode(wifi.STATION);
			wifi.sta.config(ssid, passphrase);
		end
		wifi.sta.connect();
	end

	tmr.alarm(1, 100, 1, testConnection);	-- 0.1s

	log ("main end");
end

main ();
