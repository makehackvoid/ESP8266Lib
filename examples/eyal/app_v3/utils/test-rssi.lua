-- track rssi dofile("test-rssi.lua")

savePort   = savePort   or 31883
saveServer = saveServer or "192.168.2.7"

local conn = net.createUDPSocket()
if nil == conn then print("net.create failed") end

local count = 0
tmr.alarm(1, 500, tmr.ALARM_AUTO, function()
	count = count + 1
	if wifi.STA_GOTIP ~= wifi.sta.status() then
		print (("%8.3f %4d %s"):format(tmr.now()/1000000, count, "no connection"))
		return
	end

	msg = ("%8.3f %4d %d"):format(tmr.now()/1000000, count, wifi.sta.getrssi())
	print (msg)
	conn:send (savePort, saveServer, msg.."\n")
end)
