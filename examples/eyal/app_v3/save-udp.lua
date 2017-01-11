local mLog = mLog
local function Log (...) if print_log then mLog ("save-udp", unpack(arg)) end end
local function Trace(n, new) mTrace(0x0A, n, new) end Trace (0)
used ()
out_bleep()

local conn = net.createUDPSocket()
if nil == conn then
	Trace(1)
	Log ("net.create failed")
	message = nil
	doSleep()
end

Log ("send  to '%s:%d' '%s'", saveServer, savePort, message)
conn:send(savePort, saveServer, message, function(conn)
	grace_time = tmr.now() + udp_grace_ms*1000
	Trace(2)
	Log ("sent")
	message = nil

	conn:close()
	Trace(3)
	doSleep()
end)
