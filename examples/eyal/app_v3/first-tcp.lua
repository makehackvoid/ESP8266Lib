time_First = done_file (tmr.now())
local mLog = mLog
local function Log (...) if print_log then mLog ("first", unpack(arg)) end end
local function Trace(n, new) mTrace(0x0C, n, new) end Trace (0, true)
used ()
out_bleep()

local timeout = tmr.create()
local conn

local function have_first(count)
	runCount = count
	time_First = tmr.now() - time_First
	timeout:unregister()
	if conn then
		conn:close()
		conn  = nil
	end
	do_file ("save")
end

local function first_tcp()
	conn = net.createConnection(net.TCP, 0)
	if nil == conn then
		Log ("TCP connection failed")
		have_first(1)
		return false
	end

	conn:on("disconnection", function(client, data)
		Log ("disconnected")

		if runCount then	-- probably not unexpected anymore
			Log ("unexpected disconnection, runCount=%d", runCount)
			Trace (1)	-- should not happen
		else
			Log ("connection failed")
			Trace (2)
			runCount = 1
		end

		have_first(runCount)
	end)

	conn:on("receive", function(client, data)
		Log ("received '%s'", data)
		Trace (3)

		tmr.wdclr()
		Trace (4)
		have_first(data+1)
	end)

	conn:on("sent", function(client)
		Log ("sent")
		Trace (5)
		tmr.wdclr()
	end)

	conn:on("connection", function(client)
		Log ("connected")
		Trace (6)

		tmr.wdclr()
		client:send (("last/%s"):format(clientID))	-- request last runCount
	end)

-- normally done in 1-2s
	timeout:alarm(first_timeout, tmr.ALARM_SINGLE, function()
		Log("exchange timeout")
		Trace (7)
		have_first(1)
	end)

	Trace (8)
	tmr.wdclr()
	conn:connect(savePort, saveServer)
end

first_tcp()

