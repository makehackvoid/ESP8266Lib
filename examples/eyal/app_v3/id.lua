-- example of debugging by setting different items

time_start = tmr.now()
node.setcpufreq(node.CPU160MHZ)	-- do this early

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

--[[
mem_used = collectgarbage("count")*1024
mem_heap = node.heap()
--]]

-- sleep_time = 15
-- adc_count = 10
-- print_log = true
-- print_dofile = true
-- print_stats = true
-- ow_pin = -1  -- no ow
-- ow_addr = {} -- read no sensors
-- ow_addr = {""}       -- read all autodetected sensors
-- save_proto = "tcp"
-- do_Save = false
-- send_times, send_stats, send_radio = false, false, false

if print_dofile then
	print (("%.6f %s: used %d, heap=%d"):format(
		time_start/1000000, "init", mem_used, mem_heap))
end

time_dofile = 0
start_dofile = time_start
if not pcall (function() dofile("funcs.lc", true) end) then
	print("missing funcs.lc")
else
	function Log (...) mLog ("init", unpack(arg)) end
	do_file ("main")
end
