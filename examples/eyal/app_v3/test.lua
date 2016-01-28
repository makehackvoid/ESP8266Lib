local savePort, saveServer = 21883, "192.168.2.7"
local udp_grace_ms = 1

local function Log (message, ...)
	if #arg > 0 then
		message = message:format(unpack(arg))
	end
	print (("%.6f %s"):format(tmr.now()/1000000, message))
end

local check_count = 0
tmr.alarm(1, 10, 1, function()
	check_count = check_count + 1
	if 5 ~= wifi.sta.status() then return end
	tmr.stop(1)

	Log ("have connection after %d tries", check_count)

	local conn = net.createConnection(net.UDP, 0)
	conn:on("sent", function(conn)
		Log ("sent")
		tmr.alarm(1, udp_grace_ms, 0, function()
			node.dsleep (1*1000000)
		end)
	end)

	conn:connect(savePort, saveServer)

	conn:send ("show esp-test Hello World")
end)
