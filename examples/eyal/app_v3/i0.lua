-- init.lua: minimal, production
time_start = tmr.now()
node.setcpufreq(node.CPU160MHZ)	-- do this asap
last_trace = nil	-- not yet set
time_dofile = 0
start_dofile = time_start
if not pcall (function() dofile("funcs.lc", true) end) then
	print("missing funcs.lc")
else
	function Log (...) mLog ("init", unpack(arg)) end
	local function Trace(n) mTrace(2, n) end Trace (0)
	do_file ("main")
end
