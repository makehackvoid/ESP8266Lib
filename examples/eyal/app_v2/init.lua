time_start = tmr.now()
mem_used = collectgarbage("count")*1024
mem_heap = node.heap()
----- do not change above this line -------

if true then
--	do_Save = false
--	saveServer = "192.168.3.4"
	savePort = 21883	-- alternate server
--	save_proto = "tcp"
	sleep_time = 10
--	print_log = true
--	print_dofile = true
--	print_stats = true
--	ow_pin = -1

	if print_dofile then
		print (string.format ("%.6f %s: used %d, heap=%d",
			time_start/1000000, "init", mem_used, mem_heap))
	end
end

----- do not change below this line -------
if print_stats then print("init: calling funcs.lc") end
time_dofile = 0
start_dofile = tmr.now()
dofile("funcs.lc")

function Log (...) mLog ("init", unpack(arg)) end
do_file ("main")
