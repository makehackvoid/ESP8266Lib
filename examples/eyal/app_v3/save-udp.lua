local mLog = mLog
local function Log (...) if print_log then mLog ("save-udp", unpack(arg)) end end
local function Trace(n, new) mTrace(0x0A, n, new) end Trace (0, true)
used ()
out_bleep()

local conn = net.createUDPSocket()

local function send_done(t)
	message = nil
	conn:close()
	conn = nil
	Trace (t)
	doSleep()
end

if nil == conn then
	Log ("net.createUDPSocket failed")
	Log ("message='%s'", message)
	send_done(1)
else
	local timeout = tmr.create()
	timeout:alarm(save_udp_timeout, tmr.ALARM_SINGLE, function()
		Log("send timeout")
		send_done(4)
	end)

	Log ("send  to '%s:%d' '%s'", saveServer, savePort, message)
	conn:send(savePort, saveServer, message, function(client)
		timeout:unregister()		-- turn off save_udp_timeout
		grace_time = tmr.now() + udp_grace_ms*1000
		Trace (2)
		Log ("sent")
		if not grace_method or grace_method < 0 or grace_method > 3 then
			grace_method = 0
		end
		if grace_method <= 1 then	-- 0(variable) and 1(fixed) yield before dsleep
			-- standard (no  forced_grace_time)
			-- test 1   (set forced_grace_time)
			send_done(3)
		else				-- 2 and 3: yield after send
			timeout:alarm(udp_grace_ms, tmr.ALARM_SINGLE, function()
				if 2 == grace_method then
					grace_time = nil	-- 2 yield only after send
				end
				send_done(5)
			end)
		end

	end)
end

--[[
grace_method:
  0(default):
        variable yield just before dsleep
		set udp_grace_ms (before dsleep)
  1:
        fixed   yield just before dsleep
		set forced_grace_time (before dsleep)
  2:
        yield immediately after send
		set udp_grace_ms (after send)
  3:
        yield immediately after send *and* just before dsleep
		set udp_grace_ms (after send)
		set forced_grace_time (before dsleep)
--]]

