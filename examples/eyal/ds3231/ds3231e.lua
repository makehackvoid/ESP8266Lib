local t = require("ds3231")

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
-- t.setTime(30, 56, 23, 3, 4, 3, 2015);

-- Get current time
local second, minute, hour, dow, day, month, year = t.getTime ();
print (string.format ("Date/Time %02d/%02d/%04d %02d:%02d:%02d",
	day, month, year, hour, minute, second));

-- Get temp
print(string.format("Temp: %g", t.getTemp()));

-- Get current temp
print(string.format("Temp now: %g", t.getTempNow()));

t = nil;
package.loaded["ds3231"]=nil;
ds3231 = nil;
