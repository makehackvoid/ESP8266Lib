-- init.lua: measure the time it takes for wifi connection to be established using event monitor
local start_time = tmr.now()
gpio.mode (1, gpio.INPUT, gpio.PULLUP)	-- gpio5 = D1, ground to stop test
if 0 == gpio.read (1) then print ("stopped") else
	local eventmon = wifi.eventmon
	local function die(reason)
		print (("\n%s: after %.6fs\n"):format(reason, (tmr.now()-start_time)/1000000))
		eventmon.unregister(eventmon.STA_GOT_IP)
		eventmon.unregister(eventmon.STA_DISCONNECTED)
		tmr.alarm(2, 100, 0, function()		-- 100ms, time for message to print
			rtctime.dsleep(100*1000)	-- 100ms, whatever
		end)
	end
	wifi.sta.setip({ip="192.168.2.59",netmask="255.255.255.0",gateway="192.168.2.7"})
	eventmon.register(eventmon.STA_GOT_IP, function(T) die("GOTIP") end)
	eventmon.register(eventmon.STA_DISCONNECTED, function(T) die("FAIL") end)
end
