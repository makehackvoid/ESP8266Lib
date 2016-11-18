time_start = tmr.now()
--[[
if nil ~= rtctime then
	rtc_start_s, rtc_start_u = rtctime.get()
--	print ("RTC="..rtc_start_s.."."..rtc_start_u)
end
--]]

--[[
out_pin = 5     -- gpio14 for timing test
if out_pin then
	gpio.mode (out_pin, gpio.OUTPUT)
	gpio.write(out_pin, gpio.LOW)
end
--]]

node.setcpufreq(node.CPU160MHZ)	-- do this asap

--[[
mem_used = collectgarbage("count")*1024
mem_heap = node.heap()
--]]

-------------------------------------------
----- do not change above this line -------
-------------------------------------------

if false then
	local ap = "adc"

    if "alt" == ap then	-- alternate main (e7) server
	savePort = 21883
--	sleep_time = 60
--	rfcal_rate = 4
--	ow_addr = {""}	-- read all autodetected sensors
    end

    if "timing" == ap then
	savePort = 21883	-- alternate server
	sleep_time = 10
	ow_addr = {""}		-- read all autodetected sensors
    end

    if "adc" == ap then
	savePort = 21883	-- alternate server
	sleep_time = 60
	ow_addr = {}		-- no sensors
	adc_factor = 1		-- read adc
    end

    if "raspi" == ap then
	print("wakeup IP=", wifi.sta.getip(), ", status=", wifi.sta.status())
	netMask  = netMask  or "255.255.255.0"
	if true then						-- wireless
		network  = network  or "192.168.42."
		netGW    = netGW    or (network .. "1")
		clientIP = clientIP or (network .. "49")	-- esp-202=53, NodeMCUv3=49
	else							-- wired
		network  = network  or "192.168.3."
		netGW    = netGW    or (network .. "7")
		clientIP = clientIP or (network .. "49")
	end
	saveServer, savePort = netGW, 21883
	ssid, passphrase = "Pi_AP", "Raspberry"

--	rfcal_rate = 10
--	ow_addr = {""}		-- read all autodetected sensors
--	ow_addr = {}		-- read no sensors
--	wifi.sta.disconnect()
--	wifi.sta.config("Pi_AP", "Raspberry"sid, passphrase, 1)
--	wifi.sta.setip({ip=clientIP,netmask=netMask,gateway=netGW})	-- stop DHCPC
--	wifi.setmode(wifi.STATION)
--	wifi.sta.config("Pi_AP", "Raspberry")
--	wifi.sta.autoconnect(1)

	print_log = true
	sleep_time = 5
	udp_grace_ms = 1000
	rfcal_rate = 4
    end

    if "mhv" == ap then
	print("wakeup IP=", wifi.sta.getip(), ", status=", wifi.sta.status())
	netMask  = netMask  or "255.255.255.0"
	network  = network  or "10.0.0."
	netGW    = netGW    or (network .. "1")
	clientIP = clientIP or (network .. "100")
	saveServer, savePort = netGW, 21883
	ssid, passphrase = "makehackvoid", "solderingiron43"

	print_log = true
	sleep_time = 5
	udp_grace_ms = 100
	rfcal_rate = 4
    end

    if "el" == ap then
	ssid, passphrase = "el", "test-ap"
	saveServer, savePort = "192.168.2.24", 11883
    end

--	sleep_time = 15
--	adc_count = 10
--	print_log = true
--	print_dofile = true
--	print_stats = true
--	ow_pin = -1	-- no ow
--	ow_addr = {}	-- read no sensors
--	ow_addr = {""}	-- read all autodetected sensors
--	save_proto = "tcp"
--	do_Save = false
--	send_times, send_stats, send_radio = false, false, false

	if print_dofile then
		print (("%.6f %s: used %d, heap=%d"):format(
			time_start/1000000, "init", mem_used, mem_heap))
	end
end

-------------------------------------------
----- do not change below this line -------
-------------------------------------------
if print_stats then print("init: calling funcs.lc") end
time_dofile = 0
start_dofile = tmr.now()
dofile("funcs.lc")

function Log (...) mLog ("init", unpack(arg)) end
do_file ("main")
