-- Testing: read the ds18b20 then restart

local gpio0 = 3;
local gpio2 = 4;
local gpio4 = 2;
local gpio5 = 1;

----------------------------------
----- settings section start -----
----------------------------------

-- which is the magic pin?
magic_pin   = gpio5;		-- 'nil' will disable the magic

-- what pin is the ds18b20 attached to?
ds18b20_pin = gpio4;

-- how long we sleep between runs?
sleep_time = 3*1000000;		-- 3 seconds

--------------------------------
----- settings section end -----
--------------------------------

local function main ()
	if nil ~= magic_pin then
		gpio.mode (magic_pin, gpio.INPUT);
		if 0 == gpio.read (magic_pin) then
			print ("aborting by magic");
			return;
		end
	end

	local t = require ("ds18b20");
	t.setup (ds18b20_pin);

	repeat
		temp = t.read ();
		if temp ~= nil and temp ~= "85.0" and temp ~= 85 then
			break;
		end
		tmr.delay (750000);	-- 750ms
	until false

	print ("temp=" .. temp);

	node.dsleep (sleep_time);
end

main ();
