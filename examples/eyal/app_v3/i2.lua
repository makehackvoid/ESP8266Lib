-- init.lua: minimal, using 2nd server
time_start = tmr.now()
out_pin = 5 if out_pin then gpio.mode (out_pin, gpio.OUTPUT) gpio.write(out_pin, gpio.LOW) end
node.setcpufreq(node.CPU160MHZ)	-- do this asap
	ssid, pass = "OPTUSAD57F4C", "MNTQPZAAYYDGSXV38225"	-- Peter's Raspi
	saveServer = "10.1.1.2"		-- Peter's Raspi
--	network = "10.1.1"
	netGW = "10.1.1.1"
	clientIP   = "10.1.1.20"
--	savePort = 11883		-- Peter's Raspi (default)
	sleep_time = 10
--	udp_grace_ms = 100
if pcall (function() dofile("funcs.lc", true) end) then
	function Log (...) mLog ("init", unpack(arg)) end
	local function Trace(n, new) mTrace(2, n, new) end Trace (0, true)
	do_file ("main")
else print("missing or failing funcs.lc") end
