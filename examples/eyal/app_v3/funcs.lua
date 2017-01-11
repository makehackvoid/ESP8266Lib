function mLog (modname, message, ...)
	if nil == print_log or print_log then
		if #arg > 0 then
			message = message:format(unpack(arg))
		end
		print (("%.6f %s: %s"):format (tmr.now()/1000000, modname, message))
	end
end
local function Log (...) if print_log then mLog ("funcs", unpack(arg)) end end

function done_file(now)
	local t = now - start_dofile
	time_dofile = time_dofile + t
	if print_dofile then
		Log ("dofile time %.4f", t/1000000)
	end
	return now
end

time_dofile, start_dofile = 0, time_start
done_file (tmr.now())

--abort = false
last_trace = nil
prev_module = 0
prev_trace = 0
this_trace = 0

function mTrace(mod, n, new)
	if nil ~= rtcmem then
		if not rtca_tracePoint then
			rtca_tracePoint = 127 - 8	-- see funcs.lua!
		end
		if not last_trace then			-- first call
			last_trace = rtcmem.read32(rtca_tracePoint)
		end
		if new or mod ~= prev_module then
			prev_trace = this_trace/0x100
		-- else use last prev_trace
		end
		prev_module = mod
		local t = this_trace
		this_trace = prev_trace + (mod*0x10 + n)*0x1000000
		if print_trace then
			Log("mTrace(%x, %x%s) %08x -> %08x",
				mod, n, (new and ", true" or ""), t, this_trace)
		end
		rtcmem.write32(rtca_tracePoint, this_trace)
	end
end
local function Trace(n, new) mTrace(1, n, new) end Trace (0)

function used ()
	if print_stats then
		Log("used %d, heap=%d",
			collectgarbage("count")*1024, node.heap())
	end
end

function do_file(fname, fg)
--	if  abort then
--		Log("aborting, not doing '%s'", fname)
--		return
--	end

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

local do_vdd_read_cycle = false

function safe_dsleep(us, mode)
	if print_log then
		tmr.alarm(4, 5, 0, function()
			dsleep (us, mode)
		end)
	else
		dsleep (us, mode)
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
		if do_vdd_read_cycle then
			Log ("saving vddAdjTime=%.6f", time_left/1000000)
			rtcmem.write32(rtca_vddAdjTime, time_left)
			time_left = 1	-- immed wakeup for vdd read
			rf_mode = 4	-- no wifi for vdd read
		elseif rfcal_rate then
			local runCount = runCount or 1
			rf_mode = (runCount % rfcal_rate > 0) and 2 or 1
		end
		Log("dsleep(%.3f,%d) runCount=%d", time_left/1000000, rf_mode, (runCount or 0))
--		rtctime.dsleep_aligned ((sleep_time+dsleep_delay)*rtc_rate, 0, rf_mode)
		safe_dsleep (time_left, rf_mode)
	else
		Log("doing dsleep for restart")
		safe_dsleep (1, rf_mode)
	end
end

function restart(time_left)
	if have_rtc_mem then
		local thisTime = tmr.now() + (wakeup_delay+dsleep_delay)*rtc_rate	-- us
		rtcmem.write32(rtca_lastTime, thisTime)
		local totalTime = rtcmem.read32(rtca_totalTime)
		rtcmem.write32(rtca_totalTime, totalTime + thisTime/1000)		-- ms
		rtcmem.write32(rtca_timeLeft, (time_left or 0))

		if adc_factor and vddNextTime > 0 then
			local t = rtcmem.read32(rtca_vddNextTime)
			local l = time_left or 0
			Log ("t=%.6f sleep_time=%.6f l=%.6f",
				t/1000000, sleep_time/1000000, l/1000000)
			if t > sleep_time then
				t = t - l
				rtcmem.write32(rtca_vddNextTime, t)
				Log ("time to next vdd read: %.6f", t/1000000)
			else -- if t == vddNextTime then
				rtcmem.write32(rtca_vddNextTime, vddNextTime)
				adc.force_init_mode(adc.INIT_VDD33)
				grace_time = grace_time + 43*1000	-- adc.force takes 43ms
				do_vdd_read_cycle = true
				Log ("will read vdd next wakeup")
			end
		end
	end

	if nil == time_left then
		if do_vdd_read_cycle then
			time_left = 0
		else
			return
		end
	end

	local t_delay = 0
	if grace_time then
		local t_grace = tmr.now()
		if t_grace < grace_time then
			t_delay = (grace_time - t_grace)/1000
			Log("grace delay %.3f", t_delay)
			time_left = time_left - t_delay*1000
		else
			Log("no grace delay")
		end
	end

	if t_delay >= 1 then
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
			Log("dsleep %gs", time_left/1000000)
			Trace(1, true)
			restart (time_left)
		else
			Log("restart now\n")
			Trace(2, true)
			restart (0)
		end
	elseif sleep_time < 0 then			-- wait requested
		time_left = (-sleep_time - sleep_start) / 1000
		if time_left <= 0 then
			Log("restart now\n")
			Trace(3, true)
			restart (0)
		else
			Log("restart in %gs", time_left/1000)
			tmr.alarm(2, time_left, 0, function()
				tmr.stop(2)
				Trace(4, true)
				restart (0)
			end)
		end
	else
		Log("not sleeping")
		runCount = nil	-- in case we rerun in same env
		Trace(5, true)
		restart (nil)		-- just update stats
	end
end

function incrementCounter(address)
	if not have_rtc_mem then return 1 end

	local count = rtcmem.read32(address)
	if count ~= 0xffffffff then count = count + 1 end
	rtcmem.write32(address, count)
	return count
end

