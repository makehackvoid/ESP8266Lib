-- minimal, production init.lua
time_start = tmr.now()
node.setcpufreq(node.CPU160MHZ)	-- do this asap
time_dofile = 0
start_dofile = time_start
if not pcall (function() dofile("funcs.lc", true) end) then
	print("missing funcs.lc")
else
	function Log (...) mLog ("init", unpack(arg)) end
	do_file ("main")
end
