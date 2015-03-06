-- some ESP-07 GPIO Mapping
local gpio0  = 3;	-- ESP-01, clixx o
local gpio2  = 4;	-- ESP-01, clixx i
local gpio4  = 2;
local gpio5  = 1;
local gpio14 = 5;
local gpio12 = 6;
local gpio13 = 7;

local scan_codes  = {0x07, 0x0B, 0x0D, 0x0E};
local check_codes = {0x80, 0x40, 0x20, 0x10};

-- read a simple 4x4 keypad
local keys = {};

local t = nil;

local function keypadSetup()
	-- these values depend on how the keypad is plugged in
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

	t = require("pca9555");

	t.init(gpio2, gpio0);

	-- scan the low nibble and read the high
	t.configPort0(0xF0);	-- C0.0-C0.3=out C0.4-C0.7=in
	t.polarityPort0(0xF0);	-- N0.4-N0.7=invert
end

local function keypadCleanup()
	t = nil;
	package.loaded["pca9555"] = nil;
	pca9555 = nil;
end

local function keypadCombo(scan, press)
	local key = "";
	-- key = string.format("x%02X[", scan+press);
	for j, check in ipairs(check_codes) do
		if bit.band (press, check) ~= 0 then
			combo = keys[scan+check];
			if combo == nil then
				key = key .. string.format("[%02X]", scan+check);
			else
				key = key .. combo;
			end
		end
	end
	-- key = key .. "]";
	return key;
end

local function keypadRead()
	local pressed = "";
	for i, scan in ipairs(scan_codes) do
		t.writePort0 (scan);				-- write O0.0-O0.3
		local press = bit.band (t.readPort0 (), 0xF0);	-- read  I0.4-I0.7
		if press ~= 0 then
			local key = keys[scan+press];
			if nil == key then
				key = keypadCombo(scan, press);
			end
			-- print (string.format("%2X %0X: %s", scan, press, key));
			pressed = pressed .. key;
		end
	end
	return pressed;
end

function keypadCheck()
	new = keypadRead ();
	if new ~= old then
		if new == last then
			old = new;
			if new == "" then
				print ("released");
			else
				print ("pressed: " .. new);
			end
			if "1D" == new then	-- our safe word
				tmr.stop (1);
				keypadCleanup ();
				print ("exiting");
			end
		end
		last = new;
	end
	collectgarbage();
	tmr.wdclr();
end

local old = "";
local last = "";
local new;

keypadSetup();

tmr.alarm(1, 5, 1, keypadCheck)	-- every 5ms
