if nil == time_start then time_start = tmr.now() end
m = m + 1; mods[m] = "funcs"

time_dofile = time_dofile or 0
abort = abort or false

function Log (message, ...)
	if print_log then
		local t = tmr.now()/1000000
		if 0 == #arg then
			print (string.format ("%.6f %s: %s",
				t, mods[m], message))
		else
			print (string.format ("%.6f %s: %s",
				t, mods[m],
				string.format (message, unpack(arg))))
		end
	end
end

function used ()
	if print_usage then
		Log("used %d, heap=%d",
			collectgarbage("count")*1024, node.heap())
	end
end

function do_file(fname)
	if  abort then
		Log("aborting")
		return
	end

	tmr.alarm(1, 1, 0, function()
		tmr.stop(1)
		local fullName = string.format(
			"%s%s", fname, (lua_type or ".lc"))
		if print_usage then
			Log("calling %s", fullName)
		end
		start_dofile = tmr.now()
		dofile (fullName)
	end)
end

function doSleep ()
	local time_left = 0
	if sleep_time > 0 then
		time_left = sleep_time - tmr.now()*sleep_rate
		if time_left <= 0 then
			Log("just restart\n")
			node.restart()
		else
			Log("dsleep %gs\n", time_left/1000000)
			node.dsleep (time_left, 1)	-- RC_CAL after wakeup
		end
	elseif sleep_time < 0 then
		time_left = (-sleep_time - tmr.now()*sleep_rate) / 1000
		if time_left <= 0 then
			Log("restart now\n")
			node.restart()
		else
			Log("will restart in %gs", time_left/1000)
			tmr.alarm(2, time_left, 0, function()
				tmr.stop(2)
				node.restart()
			end)
		end
	else
		Log("not sleeping")
		runCount = nil	-- in case we rerun in same env
	end
end

function incrementCounter(address)
	if not have_rtc_mem then return 1 end

	local count = misc.rtc_mem_read_int(address)
	if count ~= 0xffffffff then count = count + 1 end
	misc.rtc_mem_write_int(address, count)
	return count
end
