require("ds3231")

-- some ESP-07 GPIO Mapping
local gpio0  = 3;	-- ESP-01
local gpio2  = 4;	-- ESP-01
local gpio4  = 2;
local gpio5  = 1;
local gpio14 = 5;
local gpio13 = 6;
local gpio12 = 7;

ds3231.init(gpio2, gpio0);

-- Run ONCE and ON TIME:
-- ds3231.setTime(0, 1, 21, 3, 25, 2, 2015);

local second, minute, hour, day, date, month, year = ds3231.getTime();

-- Get current time
print(string.format("Time & Date: %02d:%02d:%02d %02d/%02d/%04d",
	hour, minute, second, date, month, year));

-- Get current temp
print(string.format("Temp: %.2g", ds3231.getTemp()));

-- Don't forget to release it after use
ds3231 = nil;
package.loaded["ds3231"]=nil;
