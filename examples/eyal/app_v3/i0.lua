-- init.lua: minimal, production
time_start = tmr.now()
node.setcpufreq(node.CPU160MHZ)	-- do this asap
if pcall (function() dofile("funcs.lc", true) end) then
	function Log (...) mLog ("init", unpack(arg)) end
	local function Trace(n, new) mTrace(2, n, new) end Trace (0)
	do_file ("main")
else print("missing or failing funcs.lc") end
