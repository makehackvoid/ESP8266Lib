local t = require("ds1307")

-- some ESP-07 GPIO Mapping
local gpio0  = 3;	-- ESP-01, clixx o
local gpio2  = 4;	-- ESP-01, clixx i
local gpio4  = 2;
local gpio5  = 1;
local gpio14 = 5;
local gpio12 = 6;
local gpio13 = 7;

t.init(gpio2, gpio0);

-- Set time: run ONCE and ON TIME:
-- t.setTime (30, 55, 16, 5, 5, 3, 2015);

-- Get current time
local second, minute, hour, dow, day, month, year = t.getTime ();
print (string.format ("Date/Time %02d/%02d/%04d %02d:%02d:%02d",
	day, month, year, hour, minute, second));

for addr = 8, 63 do
	t.writeReg (addr, addr+10)
	collectgarbage();
end

for addr = 8, 63 do
	print ("reg[" .. addr .. "]=" .. t.readReg (addr))
	collectgarbage();
end

t = nil;
package.loaded["ds1307"] = nil;
ds1307 = nil;
collectgarbage();
