local gpio0  = 3;	-- ESP-01, clixx o
local gpio2  = 4;	-- ESP-01, clixx i
local gpio4  = 2;
local gpio5  = 1;
local gpio14 = 5;
local gpio12 = 6;
local gpio13 = 7;

t = require("lm75");

t.init (gpio2 ,gpio0);
print (t.strTemp());

t = nil;
package.loaded["lm75"] = nil;
lm75 = nil;
collectgarbage();
