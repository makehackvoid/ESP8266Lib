time_dofile = time_dofile + (tmr.now()-start_dofile)
m = m + 1; mods[m] = "read-ds18b20"
used ()

local tries_ps = 100
local tries_count = 0
local tries_limit = 3*tries_ps	-- 3s

local function haveReading()
	if temp then
		Log ("have Reading %.4f after %d tries",
			temp, tries_count)
	end
	if do_WiFi then do_file ("wifi") end
end

local t = nil

local function waitforReading()
	temp = t.read()
	if temp ~= nil and temp ~= "85.0" and temp ~= 85 then
		tmr.stop(1)
		time_read = tmr.now() - time_read
		t, ds18b20, package.loaded["ds18b20"] = nil, nil, nil
		haveReading()
		return true
	end
	tries_count = tries_count + 1
	if tries_count > tries_limit then
		tmr.stop(1)
		Log ("Reading failed, aborting")
		incrementCounter(rtc_failRead_address)
		doSleep()
	end
	return false
end

if ow_pin >= 0 then
	start_dofile = tmr.now()
	m = m + 1; mods[m] = "ds18b20"
	t = require ("ds18b20")
	m = m - 1
	time_dofile = time_dofile + (tmr.now()-start_dofile)

	time_read = tmr.now()
	t.setup (ow_pin)

	if not waitforReading() then
		Log ("waiting for Reading")
		tmr.alarm(1, 1000/tries_ps, 1, waitforReading)
	end
else
	Log ("not reading temperature")
	temp = nil
	time_read = 0
	haveReading()
end

