-- init.lua: minimal, with some exmples of common settings
time_start = tmr.now()
--mem_used, mem_heap = collectgarbage("count")*1024, node.heap()
node.setcpufreq(node.CPU160MHZ)	-- do this asap
-- do not change above this line --
--	saveServer = "192.168.2.7"	-- send messages to this server
	savePort = 21883		-- send messages to this port
	sleep_time = 10			-- cycle every 10 seconds
	save_proto = "udp"		-- send message to a udp/tcp/mqtt server
--	save_proto = "mqtt"		-- send message to an mqtt server (or 'udp' or 'tcp')
	print_log = true		-- print debug messages
--	print_trace = true		-- print debug messages
	print_dofile = true		-- print 'dofile' times
--	print_usage = true		-- print memory usage stats
--	send_mem = true			-- include mem_used and mem_heap in message
-- do not change below this line --
if pcall (function() dofile("funcs.lc", true) end) then
	function Log (...) mLog ("init", unpack(arg)) end
	local function Trace(n, new) mTrace(2, n, new) end Trace (0, true)
	do_file ("main")
else print("missing or failing funcs.lc") end
