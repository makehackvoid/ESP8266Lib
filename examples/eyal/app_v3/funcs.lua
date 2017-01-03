function mLog (modname, message, ...)
	if print_log then
		if #arg > 0 then
			message = message:format(unpack(arg))
		end
		print (("%.6f %s: %s"):format (tmr.now()/1000000, modname, message))
	end
end
local function Log (...) mLog ("funcs", unpack(arg)) end

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

function mTrace(module, n)
	if nil ~= rtcmem then
		if nil == rtca_tracePoint then
			rtca_tracePoint = 127 - 8	-- see funcs.lua!
		end
		if nil == last_trace then	-- first call
			last_trace = rtcmem.read32(rtca_tracePoint)
			this_trace = 0
		end
		this_trace = this_trace/0x100 + (module*0x10 + n)*0x1000000
		rtcmem.write32(rtca_tracePoint, this_trace)
	end
end
local function Trace(n) mTrace(1, n) end Trace (0)

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

local out_state = gpio.LOW	-- was set LOW at start

function out_set(state)
	if out_pin and out_state ~= state then
		out_state = state
		gpio.write(out_pin, out_state)
	end
end

function out_bleep()
	if out_pin then
		gpio.write(out_pin, gpio.HIGH)
		gpio.write(out_pin, gpio.LOW)	-- generates a 200us bleep
		out_state = gpio.LOW
	end
end

function out_toggle()
	if out_pin then
		out_state = (gpio.LOW + gpio.HIGH) - out_state	-- may work...
		gpio.write(out_pin, out_state)
	end
end

function restart_really(time_left)
	out_bleep()

--[[
	WAKE_RF_DEFAULT  = 0 -- CAL or not after wake up, depends on init data byte 108.
	WAKE_RFCAL       = 1 -- CAL        after wake up, there will be large current.
	WAKE_NO_RFCAL    = 2 -- no CAL     after wake up, there will only be small current.
	WAKE_RF_DISABLED = 4 -- disable RF after wake up, there will be the smallest current.
--]]

	if nil ~= time_left and time_left > 0 then
		local rf_mode = 1
		if rfcal_rate then
			local runCount = runCount or 1
			rf_mode = (runCount % rfcal_rate > 0) and 2 or 1
		end
		Log("runCount=%d rf_mode=%d", runCount, rf_mode)
		if use_rtctime then
--			rtctime.dsleep_aligned ((sleep_time+dsleep_delay)*rtc_rate, 0, rf_mode)
			rtctime.dsleep (time_left, rf_mode)
		else
			node.dsleep (time_left, rf_mode)
		end
	else
		node.restart()
	end
end

function restart(time_left)
	if have_rtc_mem then
		local time_total = rtcmem.read32(rtca_totalTime)
		local time_now = tmr.now() + (wakeup_delay+dsleep_delay)*rtc_rate	-- us
		rtcmem.write32(rtca_lastTime, time_now)
		rtcmem.write32(rtca_totalTime, time_total + time_now/1000)		-- ms
		rtcmem.write32(rtca_timeLeft, (time_left or 0))
	end

	if nil == time_left then return end

	local t_delay = 0
	if grace_time then
		local t_grace = tmr.now()
		if t_grace < grace_time then
			t_delay = (grace_time - t_grace)/1000
			time_left = time_left - t_delay*1000
		end
	end

	if t_delay > 0 then
		tmr.alarm(3, t_delay, 0, function()
			restart_really(time_left)
		end)
	else
		restart_really(time_left)
	end

end

function doSleep ()
	local sleep_start = tmr.now() + wakeup_delay*rtc_rate
	local time_left
	local sleep_time = sleep_time*rtc_rate		-- us time each cycle
	if sleep_time > 0 then				-- dsleep requested
		time_left = sleep_time - (sleep_start + dsleep_delay*rtc_rate)
		if time_left > 0 then
			Log("dsleep %gs\n", time_left/1000000)
			Trace(1)
			restart (time_left)
		else
			Log("restart now\n")
			Trace(2)
			restart (0)
		end
	elseif sleep_time < 0 then			-- wait requested
		time_left = (-sleep_time - sleep_start) / 1000
		if time_left <= 0 then
			Log("restart now\n")
			Trace(3)
			restart (0)
		else
			Log("restart in %gs", time_left/1000)
			tmr.alarm(2, time_left, 0, function()
				tmr.stop(2)
				Trace(4)
				restart (0)
			end)
		end
	else
		Log("not sleeping")
		runCount = nil	-- in case we rerun in same env
		Trace(5)
		restart (nil)	-- just update stats
	end
end

function incrementCounter(address)
	if not have_rtc_mem then return 1 end

	local count = rtcmem.read32(address)
	if count ~= 0xffffffff then count = count + 1 end
	rtcmem.write32(address, count)
	return count
end

