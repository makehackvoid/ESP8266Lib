if nil ~= ds18b20_pin then
	local t = require ("ds18b20")
	t.setup (ds18b20_pin)

	repeat
		tmr.delay (10000)	-- 10ms
		temp = t.read()
	until temp ~= "85.0" and temp ~= 85
	t = nil;
	package.loaded["ds18b20"] = nil;
	collectgarbage ();
else
	temp = runCount
end
