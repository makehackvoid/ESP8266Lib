-- init.lua: standalone test: sleep 20s at a time. Abort by magic pin.
gpio.mode (1, gpio.INPUT, gpio.PULLUP)	-- gpio5 = D1
if 0 == gpio.read (1) then
	print ("aborting by magic")
else
	node.dsleep(20*1000000,4)	-- no WiFi
end
