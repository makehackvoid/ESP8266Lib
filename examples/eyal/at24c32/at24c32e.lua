-- some ESP-07 GPIO Mapping
local gpio0  = 3;	-- ESP-01, clixx o
local gpio2  = 4;	-- ESP-01, clixx i
local gpio4  = 2;
local gpio5  = 1;
local gpio14 = 5;
local gpio12 = 6;
local gpio13 = 7;

t = require("at24c32");
t.init(gpio2, gpio0);

local last1 = 2*1024-1;	-- 2K on the '32, 4K on the '64 etc. Or '512-1' for a fast test.
local last2 = last1*2 + 1;

function log (message)
	print ((tmr.now()/1000000) .. ": " .. message);
end

local function hash1(i)
	return string.char (bit.band (0x0FF, i*11));
end

local function hash2(i)
	return string.char (bit.band (0x0FF, i*11), bit.band (0x0FF, (i+1)*10));
end

-- test writing single bytes

local nErrs = 0;
for i = 0, last1 do
	if 0 == i%100 then log ("write 1: " .. i) end
	if t.write (i, hash1(i)) == 0 then
		log ("[" .. i .. "] write failed");
		nErrs = nErrs + 1;
	end
	tmr.wdclr();
end
log ("done writing 1, nErrs=" .. nErrs);

nErrs = 0;
for i = 0, last1 do
	if 0 == i%100 then log ("read 1: " .. i) end
	local data = t.read (i);
	if data == nil then
		log ("[" .. i .. "] read failed");
		nErrs = nErrs + 1;
	else
		if data ~= hash1(i) then
			log ("[" .. i .. "]=" .. data);
			nErrs = nErrs + 1;
		end
	end
	tmr.wdclr();
end
log ("done reading 1, nErrs=" .. nErrs);

-- test writing blocks of 2 bytes

nErrs = 0;
for i = last1+1, last2, 2 do
	if 0 == i%100 then log ("write 2: " .. i) end
	if t.write (i, hash2(i)) == 0 then
		log ("[" .. i .. "] write failed");
		nErrs = nErrs + 1;
	end
	tmr.wdclr();
end
log ("done writing 2, nErrs=" .. nErrs);

nErrs = 0;
for i = last1+1, last2, 2 do
	if 0 == i%100 then log ("read 2: " .. i) end
	local data = t.read (i, 2);
	if data == nil then
		log ("[" .. i .. "] read failed");
		nErrs = nErrs + 1;
	else
		if data ~= hash2(i) then	-- use hash1() to provoke read errors
			log ("[" .. i .. "]=" .. data);
			nErrs = nErrs + 1;
		end
	end
	tmr.wdclr();
end
log ("done reading 2, nErrs=" .. nErrs);

t = nil;
package.loaded["at24c32"] = nil;
at24c32 = nil;
