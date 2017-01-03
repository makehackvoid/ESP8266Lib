-- init.lua: minimal, with some exmples of common settings
time_start = tmr.now()
node.setcpufreq(node.CPU160MHZ)	-- do this asap
last_trace = nil	-- not yet set
-- do not change above this line --
--	saveServer = "192.168.2.7"	-- send messages to this server
--	savePort = 21883		-- send messages to this port
--	sleep_time = 10			-- cycle every 10 seconds
--	save_proto = "udp"		-- send message to a udp/tcp/mqtt server
--	save_proto = "mqtt"		-- send message to an mqtt server (or 'udp' or 'tcp')
--	print_log = true		-- print debug messages
--	print_dofile = true		-- print 'dofile' times
--	print_usage = true		-- print memory usage stats
-- do not change below this line --
time_dofile = 0
start_dofile = time_start
if not pcall (function() dofile("funcs.lc", true) end) then
	print("missing funcs.lc")
else
	function Log (...) mLog ("init", unpack(arg)) end
	local function Trace(n) mTrace(2, n) end Trace (0)
	do_file ("main")
end
