function Log (...) mLog ("funcs", unpack(arg)) end

function mLog (modname, message, ...)
	if print_log then
		if #arg > 0 then
			message = message:format(unpack(arg))
		end
		print (("%.6f %s: %s"):format (tmr.now()/1000000, modname, message))
	end
end

function done_file(now)
	local t = now - start_dofile
	time_dofile = time_dofile + t
	if print_dofile then
		Log ("dofile time %.4f", t/1000000)
	end
	return now
end

done_file (tmr.now())

abort = false

function used ()
	if print_stats then
		Log("used %d, heap=%d",
			collectgarbage("count")*1024, node.heap())
	end
end

function do_file(fname, fg)
	if  abort then
		Log("aborting")
		return
	end

	local fullName = ("%s%s"):format(fname, (lua_type or ".lc"))
	if print_dofile then
		Log("calling %s", fullName)
	end
	if fg then
		start_dofile = tmr.now()
		dofile (fullName)
	else
		tmr.alarm(1, 1, 0, function()
			tmr.stop(1)
			start_dofile = tmr.now()
			dofile (fullName)
		end)
	end
end

function restart(time_left)
	if have_rtc_mem then
		local time_total = rtcmem.read32(
					rtca_totalTime)
		local time_now = tmr.now()			-- us
		rtcmem.write32(rtca_lastTime,
			time_now)
		time_total = time_total + time_now / 1000	-- ms
		rtcmem.write32(rtca_totalTime,
			time_total)
	end

	if nil ~= time_left and time_left > 0 then
		node.dsleep (time_left, 1)	-- RC_CAL after
	else
		node.restart()
	end
end

function doSleep ()
	local time_left = 0
	local sleep_time = sleep_time*sleep_rate
	local sleep_start = tmr.now()+sleep_tmr_delay
	if sleep_time > 0 then
		time_left = sleep_time - sleep_start
		if time_left <= 0 then
			Log("restart now\n")
			restart ()
		else
			Log("dsleep %gs\n", time_left/1000000)
			restart (time_left)
		end
	elseif sleep_time < 0 then
		time_left = (-sleep_time - sleep_start) / 1000
		if time_left <= 0 then
			Log("restart now\n")
			restart ()
		end

		Log("will restart in %gs", time_left/1000)
		tmr.alarm(2, time_left, 0, function()
			tmr.stop(2)
			restart ()
		end)
	else
		Log("not sleeping")
		runCount = nil	-- in case we rerun in same env
	end
end

function incrementCounter(address)
	if not have_rtc_mem then return 1 end

	local count = rtcmem.read32(address)
	if count ~= 0xffffffff then count = count + 1 end
	rtcmem.write32(address, count)
	return count
end
