-- setup for esp8266 MAC 18-FE-34-FE-85-3D

local gpio0  = 3	-- ESP-01, clixx o
local gpio2  = 4	-- ESP-01, clixx i
local gpio4  = 2
local gpio5  = 1
--local gpio12 = 6
--local gpio13 = 7
--local gpio14 = 5

clientID      = clientID      or "esp-12a"
network       = network       or "192.168.2."
netGW         = netGW         or (network .. "7")
clientIP      = clientIP      or (network .. 36)

magic_pin     = magic_pin     or gpio5
sleep_time    = sleep_time    or 60
sleep_rate    = sleep_rate    or 1.0346
adc_factor    = adc_factor    or 12	-- (10+.91)/.91
read_device   = read_device   or "ds18b20"
ow_pin        = ow_pin        or gpio4
ow_addr       = ow_addr       or {
			"\040\255\157\227\000\021\003\035", -- #1 low
			"\040\255\197\069\021\020\000\113", -- #2 mid
			"\040\255\208\048\044\004\000\074", -- #3 high
			"\040\255\093\029\021\021\002\068"  -- #4 south
		}
