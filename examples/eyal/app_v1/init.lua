mods = {}; m = 1; mods[m] = {"init"}
time_start = tmr.now()
dofile("funcs.lc")
m = m - 1
----- do not change above this line -------
if false then	--################################
	saveServer = "192.168.3.4"
--	save_proto = "tcp"
	sleep_time = 3*1000000
	print_log = true
	print_usage = true
	--ow_pin = -1
end		--################################

local function setup_host(host, magic, sleep, rate, device, ow, sda, scl)
	clientID      = host
	magic_pin     = magic_pin     or magic
	sleep_time    = sleep_time    or sleep*1000000
	sleep_rate    = sleep_rate    or rate
	read_device   = read_device   or device
	ow_pin        = ow_pin        or ow
	i2c_SDA       = i2c_SDA       or sda
	i2c_SCL       = i2c_SCL       or scl
end

local function get_host()
	local gpio0  = 3	-- ESP-01, clixx o
	local gpio2  = 4	-- ESP-01, clixx i
	local gpio4  = 2
	local gpio5  = 1

	local mac = wifi.sta.getmac()

	--		     host      magic      sleep   device    ow   sda    scl
	if     mac == "18-FE-34-98-DE-A1" then
		setup_host ("esp-01",  gpio0, -60, 1.0, "ds18b20", gpio2)
	elseif mac == "18-FE-34-9C-DA-B6" then
		setup_host ("esp-07",  gpio5,  60, 1.0, "ds18b20", gpio4)
	elseif mac == "18-FE-34-A0-5A-A1" then
		setup_host ("esp-12",  gpio5,  60, 1.0, "ds18b20", gpio4)
	elseif mac == "18-FE-34-A0-E1-1C" then
		setup_host ("esp-201", gpio5,  60, 1.0, "ds18b20", gpio4)
	elseif mac == "18-FE-34-9B-99-1E" then
		setup_host ("esp-kit", gpio5,  60, 1.0, "ds18b20", gpio4)
	elseif mac == "18-FE-34-98-89-67" then
		setup_host ("nodeMCU", gpio5,  60, 1.0, "ds18b20", gpio4)
	end
	setup_host = nil
end

if nil == clientID then get_host() end
get_host = nil

----- do not change below this line -------
if not abort then
	start_dofile = tmr.now()
	dofile("main.lc")
end
