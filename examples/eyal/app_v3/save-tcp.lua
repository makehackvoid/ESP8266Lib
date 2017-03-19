local mLog = mLog
local function Log (...) if print_log then mLog ("save-tcp", unpack(arg)) end end
local function Trace(n, new) mTrace(9, n, new) end Trace (0, true)
used ()
out_bleep()

local conn = net.createConnection(net.TCP, 0)
if nil == conn then
	Trace(5)
	Log ("net.createConnection failed")
	Log ("message='%s'", message)
	message = nil
	doSleep()
else
	conn:on("disconnection", function(client)
		Trace(4)
		tmr.stop(1)
		Log ("disconnected")

		conn = nil
		doSleep()
	end)

	conn:on("sent", function(client)
		Trace(2)
		Log ("sent")
	end)

	conn:on("connection", function(client)
		Trace(1)
		Log ("connected")

		Log ("send '%s'", message)
		client:send (message)
		message = nil
	end)

	Log("connecting to %s:%d", saveServer, savePort)
	tmr.alarm(1, save_tcp_timeout, tmr.ALARM_SINGLE, function()
		Log("send timeout")
		Trace(6)
		conn = nil
		message = nil
		doSleep()
	end)
	conn:connect(savePort, saveServer)
end
