local mLog = mLog
local function Log (...) if print_log then mLog ("save-tcp", unpack(arg)) end end
local function Trace(n, new) mTrace(9, n, new) end Trace (0)
used ()
out_bleep()

local conn = net.createConnection(net.TCP, 0)

conn:on("sent", function(conn)
	Trace(2)
	Log ("sent")
	message = nil

	conn:close()
	Trace(3)
	doSleep()
end)

conn:on("connection", function(conn)
	Trace(1)
	Log ("connected")

	Log ("send '%s'", message)
	conn:send (message)
end)

Log("connecting to %s:%d", saveServer, savePort)
conn:connect(savePort, saveServer)
