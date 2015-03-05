local t = require("pca9555")

-- some ESP-07 GPIO Mapping
local gpio0  = 3;	-- ESP-01, clixx o
local gpio2  = 4;	-- ESP-01, clixx i
local gpio4  = 2;
local gpio5  = 1;
local gpio14 = 5;
local gpio12 = 6;
local gpio13 = 7;

t.init(gpio2, gpio0);

-- scan the low nibble and read the high one
t.configPort0(0xF0);	-- C0.0-C0.3=out C0.4-C0.7=in
t.polarityPort0(0xF0);	-- N0.4-N0.7=invert

local scan_codes = {0x0E, 0x0D, 0x0B, 0x07};

-- read a simple 4x4 keypad
-- the values depend on how the keypad is plugged in
local keys = {};
keys[0x87] = "1";
keys[0x8B] = "2";
keys[0x8D] = "3";
keys[0x8E] = "A";

keys[0x47] = "4";
keys[0x4B] = "5";
keys[0x4D] = "6";
keys[0x4E] = "B";

keys[0x27] = "7";
keys[0x2B] = "8";
keys[0x2D] = "9";
keys[0x2E] = "C";

keys[0x17] = "*";
keys[0x1B] = "0";
keys[0x1D] = "#";
keys[0x1E] = "D";

local function reading()
	local pressed = "";
	local i, code;
	for i, code in ipairs(scan_codes) do
		t.writePort0 (code);				-- write O0.0-O0.3
		local press = bit.band (t.readPort0 (), 0xF0);	-- read  I0.4-I0.7
		if press ~= 0 then
			local key = keys[code+press];
			if nil == key then key = "X" end
			-- print (string.format("%2X %0X: %s", code, press, key));
			pressed = pressed .. key;
		end
	end
	return pressed;
end

local old = "";
local last = "";
local new;

repeat
	new = reading ();
	if new ~= old then
		if new == last then
			old = new;
			if new == "" then
				print ("released");
			else
				print ("pressed: " .. new);
			end
--[[our safe word]]	if "D1" == new then break end
		end
		last = new;
	end
	tmr.delay (5*1000);	-- 5ms
	collectgarbage();
	tmr.wdclr();
until false

t = nil;
package.loaded["pca9555"]=nil;
pca9555 = nil;
