-- default setup for esp8266 (MAC unknown)

local gpio0  = 3	-- ESP-01, clixx o
local gpio2  = 4	-- ESP-01, clixx i
local gpio4  = 2
local gpio5  = 1
--local gpio12 = 6
--local gpio13 = 7
--local gpio14 = 5

clientID      = clientID      or "esp-test"
network       = network       or "192.168.2."
netGW         = netGW         or (network .. "7")
clientIP      = clientIP      or (network .. 99)

magic_pin     = magic_pin     or gpio5
sleep_time    = sleep_time    or 60
sleep_rate    = sleep_rate    or 1.0
adc_factor    = adc_factor    or 0
read_device   = read_device   or "ds18b20"
ow_pin        = ow_pin        or gpio4
ow_addr       = ow_addr       or {nil}
