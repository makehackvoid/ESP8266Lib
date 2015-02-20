if nil ~= ds18b20_pin then
	log ("reading ds18b20");
	local t = require ("ds18b20")
	t.setup (ds18b20_pin)

	time_read = tmr.now()
	repeat
		temp = t.read()
		if temp ~= nil and temp ~= "85.0" and temp ~= 85 then
			break
		end
		tmr.delay (750000)	-- 750ms
	until false
	time_read = (tmr.now() - time_read) / 1000000
	t = nil;
	package.loaded["ds18b20"] = nil;
	ds18b20 = nil;
	collectgarbage ();
else
	temp = nil
end
