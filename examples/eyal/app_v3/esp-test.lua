-- default setup for esp8266 (MAC unknown)

--[[
	func	gpio	gpio	func
	----	----	----	----
		 antenna
	rst	.	 1	tx
	adc	.	 3	rx
	en	.	 5	scl
	wake	16	 4	sca
	sck	14	 0
	miso	12	 2
	mosi	13	15	cs
	3.3v	+	-	gnd
--]]

--local gpio0  = 3	-- 3 above gnd, ESP-01, clixx o
--local gpio1  = 10	-- 7 above ground (1st from top,Tx)
--local gpio2  = 4	-- 2 above gnd, ESP-01, clixx i
--local gpio3  = 9	-- 6 above ground (2nd from top, Rx)
  local gpio4  = 2	-- 4 above gnd (4th from top)
  local gpio5  = 1	-- 5 above gnd (3rd from top)
--local gpio11 = N/A
--local gpio12 = 6	-- 2 above vcc
  local gpio13 = 7	-- 1 above vcc
  local gpio14 = 5	-- 3 above vcc
--local gpio15 = 8	-- 1 above gnd (CS)

clientID      = clientID      or "esp-test"
network       = network       or "192.168.2."
netGW         = netGW         or (network .. "7")
clientIP      = clientIP      or (network .. "99")

  magic_pin   = magic_pin     or gpio5
  log_pin     = log_pin       or gpio13
--out_pin     = out_pin       or gpio14	-- for timing test

sleep_time    = sleep_time    or 60
rtc_rate      = rtc_rate      or 1.0
vdd_factor    = vdd_factor    or 1

read_device   = read_device   or "ds18b20"
ow_pin        = ow_pin        or gpio4
ow_addr       = ow_addr       or {""}	-- autodetect

