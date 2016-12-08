-- minimal, test init.lua
time_start = tmr.now()
node.setcpufreq(node.CPU160MHZ)	-- do this asap
	savePort = 21883	-- alternate main (e7) server
	sleep_time = 10
time_dofile = 0
start_dofile = time_start
if not pcall (function() dofile("funcs.lc", true) end) then
	print("missing funcs.lc")
else
	function Log (...) mLog ("init", unpack(arg)) end
	do_file ("main")
end
