-- setup for esp8266 MAC 18-FE-34-FE-85-3D

done_file (tmr.now())

  local gpio0  = 3	-- 3 above gnd, ESP-01, clixx o
  local gpio2  = 4	-- 2 above gnd, ESP-01, clixx i
  local gpio4  = 2	-- 4 above gnd (4th from top)
  local gpio5  = 1	-- 5 above gnd (3rd from top)
  local gpio12 = 6	-- 2 above vcc
  local gpio13 = 7	-- 1 above vcc
  local gpio14 = 5	-- 3 above vcc
  local gpio15 = 8	-- 1 above gnd (CS)
  local gpio16 = 0	-- 4 above vcc (~wake)

clientID      = clientID      or "esp-12a"
network       = network       or "192.168.2."
netGW         = netGW         or (network .. "7")
clientIP      = clientIP      or (network .. "36")

  log_pin     = log_pin       or gpio13
  magic_pin   = magic_pin     or gpio5
--out_pin     = out_pin       or gpio14 -- for timing test

sleep_time    = sleep_time    or 60
rtc_rate      = rtc_rate      or 1.02	-- empirical for 1m
vdd_factor    = vdd_factor    or 1.01	-- empirical
--adc_factor    = adc_factor    or 1	-- empirical

--[[
read_device   = read_device   or {"bme280"}
i2c_SDA       = i2c_SDA       or gpio0
i2c_SCL       = i2c_SCL       or gpio2
--]]

read_device   = read_device   or {"ds18b20"}
ow_pin        = ow_pin        or gpio4
ow_addr       = ow_addr       or {
				"\040\095\190\242\006\000\000\094",
			}

