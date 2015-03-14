--collectgarbage()
used ("doRead")

local function ReadDS3231()
	---log ("reading ds3231");
--used ("doRead -require")
	local t = require ("ds3231")
--used ("doRead +require")
	if not t.setup (i2c_SDA, i2c_SCL) then
		log ("ds3231 setup failed")
		abort = true
		return
	end

	time_read = tmr.now()

	local second, minute, hour, dow, day, month, year = t.getTime ()
	timestamp = string.format ("%04d%02d%02d%02d%02d%02d",
		year, month, day, hour, minute, second)

	temp = t.getTempNow()

	if abuseAlarm then
		if nil == runCount then
			runCount = t.getAlarm(2)
			if nil == runCount then
				runCount = 9999999	-- or what?
			else
				runCount = runCount + 1
			end
		end
		t.setAlarm (2, runCount)
	end

	time_read = (tmr.now() - time_read) / 1000000
	log("temp=" .. temp .. " time=" .. timestamp)
end

local function doRead()
	if i2c_SDA >= 0 then
		ReadDS3231 ()
		used ("doRead end")

		t, ds3231, package.loaded["ds3231"] = nil, nil, nil
		-- expecting no more i2c usage
		i2clib, package.loaded["i2clib"] = nil, nil
	else
		log ("not reading temperature");
		temp = nil;
	end
end

doRead()
--collectgarbage()
