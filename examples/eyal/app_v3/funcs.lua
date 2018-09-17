-- this makes no difference in this app:
-- node.egc.setmode(node.egc.ON_ALLOC_FAILURE)	-- default is ALWAYS

local Rr = rtcmem.read32
local Rw = rtcmem.write32

function mLog (modname, message, ...)
	if nil == print_log or print_log then
--print (modname, message)
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

last_trace = nil
prev_module = 0
prev_trace_h, prev_trace_l = 0, 0
last_trace_h, last_trace_l = 0xffffffff, 0xffffffff
this_trace_h, this_trace_l = 0, 0

function mTrace(mod, n, new)
	if nil == rtcmem then return end

	if not RtracePointH then
		RtracePointH = 127 - 8	-- see main.lua!
		RtracePointL = RtracePointH - 1
	end
	if 0xffffffff == last_trace_h then	-- first call
		last_trace_h = Rr(RtracePointH)
		last_trace_l = Rr(RtracePointL)
	end
	if new or mod ~= prev_module then
		local h = this_trace_h%0x100	-- low two digits
		prev_trace_h = (this_trace_h-h)/0x100
		local l = this_trace_l%0x100
		prev_trace_l = h*0x1000000 + (this_trace_l-l)/0x100
	-- else use last prev_trace
	end
	prev_module = mod
	local t_h, t_l = this_trace_h, this_trace_l
	this_trace_h = prev_trace_h + (mod*0x10 + n)*0x1000000
	this_trace_l = prev_trace_l
	if print_trace then
		Log("mTrace(%x, %x%s) %08x%08x -> %08x%08x",
			mod, n, (new and ", true" or ""),
			t_h, t_l, this_trace_h, this_trace_l)
	end
	Rw(RtracePointH, this_trace_h)
	Rw(RtracePointL, this_trace_l)
end
local function Trace(n, new) mTrace(1, n, new) end Trace (0, true)

function used ()
	if print_stats then
		Log("used %d, heap=%d",
			collectgarbage("count")*1024, node.heap())
	end
end

function do_file(fname, fg)
	lua_type = lua_type or ".lc"
	local fullName = ("%s%s"):format(fname, (lua_type))
	if not file.exists(fullName) then
		if '.lc' == lua_type then
			fullName = ("%s%s"):format(fname, ".lua")
		else
			fullName = ("%s%s"):format(fname, ".lc")
		end
		if not file.exists(fullName) then
			Log("no file '%s'", fname)
			return false
		end
	end

	if print_dofile then
		Log("dofile call %s", fullName)
	end
	if fg then
		start_dofile = tmr.now()
		dofile (fullName)
	else
		tmr.create():alarm(1, tmr.ALARM_SINGLE, function()
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
	if us < 10 then us = 10 end	-- SDK 2.1.0 cannot handle short periods
	if print_log then
		tmr.create():alarm(5, tmr.ALARM_SINGLE, function()
			out_bleep()
			dsleep (us, mode, 1)
		end)
	else
		out_bleep()
		dsleep (us, mode, 1)
	end
end

local function update_times(time_left)
	if not have_rtc_mem then return end

	local thisTime = tmr.now() + (dsleep_delay+wakeup_delay)*rtc_rate	-- us
	Rw(RlastTime, thisTime)					-- us
	Ri(RtotalTime, (thisTime+500)/1000)			-- ms
	if not connected then			-- tally unreported uptime
		Ri(RfailTime, (Rr(RlastTime)+500)/1000)		-- ms
	end
	Rw(RtimeLeft, (time_left or 0))				-- us
end

function restart_really(time_left)
--	if dsleep ~= node.dsleep and ow_pin then
--		gpio.mode (ow_pin, gpio.INPUT, gpio.PULLUP)
--	end

--[[
	WAKE_RF_DEFAULT  = 0 -- CAL or not after wake up, depends on init data byte 108.
	WAKE_RFCAL       = 1 -- CAL        after wake up, there will be large current.
	WAKE_NO_RFCAL    = 2 -- no CAL     after wake up, there will only be small current.
	WAKE_RF_DISABLED = 4 -- disable RF after wake up, there will be the smallest current.
--]]

	update_times(time_left)

	if nil ~= time_left and time_left > 0 then
		local rf_mode = 1
		if do_vdd_read_cycle then
			Log ("saving vddAdjTime=%.6f", time_left/1000000)
			Rw(RvddAdjTime, time_left)
			time_left = 1	-- immed wakeup for vdd read
			rf_mode = 4	-- no wifi for vdd read
		elseif rfcal_rate then
			local runCount = runCount or 1
			rf_mode = (runCount % rfcal_rate > 0) and 2 or 1
		end
		Log("dsleep(%.3f,%d) runCount=%d", time_left/1000000, rf_mode, (runCount or 0))
--		rtctime.dsleep_aligned ((sleep_time+wakeup_delay)*rtc_rate, 0, rf_mode)
		safe_dsleep (time_left, rf_mode)
	else
		Log("doing dsleep(1) for restart, runCount=%d", (runCount or 0))
		safe_dsleep (1, rf_mode)
	end
end

function restart(time_left)
	if have_rtc_mem then
		if adc_factor and vddNextTime > 0 then
			local t = 1000*Rr(RvddNextTime)			-- ms -> us
			local l = time_left or 0
			Log ("t=%.6f sleep_time=%.6f l=%.6f",
				t/1000000, sleep_time/1000000, l/1000000)
			if t > sleep_time then
				t = t - l
				Rw(RvddNextTime, (t+500)/1000)		-- us -> ms
				Log ("time to next vdd read: %.6f", t/1000000)
			else
				Rw(RvddNextTime, vddNextTime)		-- ms
				adc.force_init_mode(adc.INIT_VDD33)
				local gt = tmr.now() + 43*1000		-- adc.force takes 43ms
				if not grace_time or grace_time < gt then
					grace_time = gt
				end
				do_vdd_read_cycle = true
				Log ("will read vdd next wakeup")
			end
		end
	end

	if nil == time_left then
		if do_vdd_read_cycle then
			time_left = 0
		else
			update_times(time_left)
			return
		end
	end

	local t_delay = 0
	if connected and grace_time then
		local t_grace = tmr.now()
		if t_grace < grace_time then
			t_delay = (grace_time - t_grace +500)/1000
			Log("grace delay %.3f", t_delay)
			time_left = time_left - t_delay*1000
		else
			Log("no grace delay")
		end

		if nil ~= forced_grace_time and t_delay < forced_grace_time then
			Log("forced grace delay of %dms for %s", forced_grace_time, clientID)
			time_left = time_left - (forced_grace_time-t_delay)*1000
			t_delay = forced_grace_time
		end
	end

	if t_delay >= 1 then
		tmr.create():alarm(t_delay, tmr.ALARM_SINGLE, function()
			restart_really(time_left)
		end)
	else
		restart_really(time_left)
	end

end

function doSleep ()
	local sleep_start = tmr.now() + dsleep_delay*rtc_rate
	local time_left
	local sleep_time = sleep_time*rtc_rate		-- us time each cycle
	if sleep_time > 0 then				-- dsleep requested
		time_left = sleep_time - (sleep_start + wakeup_delay*rtc_rate)
		if time_left > 0 then
			Log("dsleep %gs", time_left/1000000)
			Trace (1, true)
			restart (time_left)
		else
			Log("restart now\n")
			Trace (2, true)
			restart (0)
		end
	elseif sleep_time < 0 then			-- wait requested
		time_left = (-sleep_time - sleep_start +500) / 1000
		if time_left <= 0 then
			Log("restart now\n")
			Trace (3, true)
			restart (0)
		else
			Log("restart in %gs", time_left/1000)
			tmr.create():alarm(time_left, tmr.ALARM_SINGLE, function()
				Trace (4, true)
				restart (0)
			end)
		end
	else
		Log("not sleeping")
		runCount = nil	-- in case we rerun in same env
		Trace (5, true)
		restart (nil)		-- just update stats
	end
end

function Ri(address, increment)		-- was incrementCounter
	if not increment then increment = 1 end
	if not have_rtc_mem then return increment end

	local count = Rr(address)
	if count ~= 0xffffffff then count = count + increment end
	Rw(address, count)
	return count
end

