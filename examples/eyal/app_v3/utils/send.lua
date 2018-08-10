-- send a file from SPIFFS on the ESP to a capture program (e.g. netcat) using UDP.

-- WiFi should be already set up
-- Run this program as
--    filename="test.lua" dofile("send.lua")
-- On the server I run:
--    ncat -ul 31883 >test.lua

local tmr = tmr
local start_time = tmr.now()
local wifi = wifi

local saveServer    = saveServer    or "192.168.2.7"
local savePort      = savePort      or 31883
local send_timeout  = send_timeout  or 5000	-- ms
local send_delay    = send_delay    or 10	-- ms, may need a longer delay!
local show_progress = show_progress or true

local conn
local prog_timer = tmr.create()
local send_timer = tmr.create()
local sent_bytes = 0

local function Log (message, ...)
        if #arg > 0 then
                message = message:format(unpack(arg))
        end
        print (("%.6f %s"):format ((tmr.now()-start_time)/1000000, message))
end

local function send_chunk()
	data = file.read()
	if data == nil then
		Log ("EOF, sent %d bytes from '%s'", sent_bytes, filename)
		file.close()
		prog_timer:unregister()
		send_timer:unregister()
		return false
	end
	if show_progress then
		Log ("read %d bytes", #data)
	end

-- Unforunately, UDP raises "sent" before the packet was sent so it is
-- not possible to immediately send more packets. This is a hack.
	send_timer:alarm(send_delay, tmr.ALARM_SINGLE, function()
		sent_bytes =  sent_bytes + #data
		conn:send(savePort, saveServer, data)
	end)
end

local function send_file()
	if not filename then
		Log("set 'filename='")
		return false
	end
	local fh = file.open(filename, "r")
	if nil == fh then
		Log("failed to open '%s'", fname)
		return false
	end

	local status = wifi.sta.status()
	if wifi.STA_GOTIP ~= status then
		Log("WiFi not set up, status=%d", status)
		return false
	end

	conn = net.createUDPSocket()
	if nil == conn then
		Log ("net.createUDPSocket failed")
		return false
	end

	prog_timer:alarm(send_timeout, tmr.ALARM_SINGLE, function()
		Log("send timeout")
		return false
	end)

	conn:on("sent", function()
		send_chunk()
	end)
	send_chunk()
end

send_file()

