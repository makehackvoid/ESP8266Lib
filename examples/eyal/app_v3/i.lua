time_start = tmr.now()
node.setcpufreq(node.CPU160MHZ)	-- do this asap
--mem_used = collectgarbage("count")*1024
--mem_heap = node.heap()
----- do not change above this line -------

if true then
--	do_Save = false

-- main alternate server
	savePort = 21883

-- raspi
--	saveServer, savePort = "192.168.3.25", 11883

-- el
--	ssid, passphrase = "el", "test-ap"
--	saveServer, savePort = "192.168.2.24", 11883

	sleep_time = 60

--	adc_count = 10
--	adc_factor    = adc_factor    or 15
--	print_log = true
--	print_dofile = true
--	print_stats = true
--	ow_pin = -1	-- no ow
--	ow_addr = {nil}	-- read any connected sensor
--	save_proto = "tcp"

--	send_times, send_stats = false, false

	if print_dofile then
		print (("%.6f %s: used %d, heap=%d"):format(
			time_start/1000000, "init", mem_used, mem_heap))
	end
end

----- do this early to (hopefully) not clash with wifi ------------

if false then
	vbat = adc.read(0)
	if true then
		if node.readvdd33 then
			vdd33 = node.readvdd33()	-- new way
		else
			vdd33 = adc.readvdd33()		-- old way
		end
		if not vdd33 then
			vdd33 = 3300			-- dummy
		end
	else
		vdd33 = 3300				-- dummy
	end
end

----- do not change below this line -------
if print_stats then print("init: calling funcs.lc") end
time_dofile = 0
start_dofile = tmr.now()
dofile("funcs.lc")

function Log (...) mLog ("init", unpack(arg)) end
do_file ("main")
