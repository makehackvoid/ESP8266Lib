-- setup for esp8266 MAC 18-FE-34-FE-85-3D

--local gpio0  = 3	-- ESP-01, clixx o
--local gpio2  = 4	-- ESP-01, clixx i
local gpio4  = 2
local gpio5  = 1
--local gpio12 = 6
--local gpio13 = 7
--local gpio14 = 5

clientID      = clientID      or "esp-12a"
network       = network       or "192.168.2."
netGW         = netGW         or (network .. "7")
clientIP      = clientIP      or (network .. "36")

magic_pin     = magic_pin     or gpio5
sleep_time    = sleep_time    or 60
rtc_rate      = rtc_rate      or 1.024	-- empirical for 1m
vdd_factor    = vdd_factor    or 1.015	-- empirical
read_device   = read_device   or "ds18b20,bme280"
ow_pin        = ow_pin        or gpio4
ow_addr       = ow_addr       or {
				"\040\210\144\118\006\000\000\115",
			  }
