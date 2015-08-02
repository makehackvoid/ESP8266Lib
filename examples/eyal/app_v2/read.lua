function Log (...) mLog ("read", unpack(arg)) end
done_file (tmr.now())
used ()

local tries_ps = 100
local tries_count = 0
local tries_limit = 1.5*tries_ps	-- 1.5s

local function haveReadings(nTemps)
	if print_log and temp then
		local tCs = ""
		local tSep = ""
		for n = 1,nTemps do
			tCs = string.format ("%s%s%.4f", tCs, tSep,
				(temp[n] or 0))
			tSep = ","
		end
		Log ("have Reading %s after %d tries",
			tCs, tries_count)
	end
	read_ds18b20, waitforReading = nil, nil
	if do_WiFi then do_file ("wifi") end
end

local t = nil

local function waitforReading()
	tries_count = tries_count + 1
	local done = true
	for n = 1,#ow_addr do
		if not temp[n] then
			local tC = t.read(ow_addr[n])
			if tC ~= nil and tC ~= "85.0" and tC ~= 85 then
				temp[n] = tC
			else
				done = false
			end
		end
	end

	if done then
		if tries_count > 1 then tmr.stop(1) end
		time_read = tmr.now() - time_read
		t, ds18b20, package.loaded["ds18b20"] = nil, nil, nil
		haveReadings(#ow_addr)
		return true
	end

	if tries_count >= tries_limit then
		tmr.stop(1)
		Log ("Reading failed, aborting")
		incrementCounter(rtc_failRead_address)
		doSleep()
	end
	return false
end

local function read_ds18b20 ()
	if print_stats then Log("calling ds18b20") end
	start_dofile = tmr.now()
	t = require ("ds18b20")
	done_file (tmr.now())

	time_read = tmr.now()
	t.setup (ow_pin)	-- no result provided

	if not waitforReading() then
		Log ("waiting for Reading")
		tmr.alarm(1, 1000/tries_ps, 1, waitforReading)
	end
end

--[[local function read_ds3231()
	if print_stats then Log("calling ds3231") end
	start_dofile = tmr.now()
	local t = require ("ds3231")
	done_file (tmr.now())

	time_read = tmr.now()
	if not t.setup (i2c_SDA, i2c_SCL) then
		Log ("ds3231 setup failed")
		abort = true
		return
	end

	tmr.wdclr()
	temp[1] = t.getTemp()

	haveReadings(#temp)
end--]]

if not abort then
	temp = {nil}
	if read_device == "ds18b20" then
		if ow_pin >= 0 then
			read_ds18b20()
		else
			Log ("no ow pin, not reading ds18b20")
			time_read = 0
			haveReadings(#temp)
		end
--[[	elseif read_device == "ds3231" then
		if i2c_SDA >= 0 and i2c_SCL >= 0 then
			read_ds3231()
			read_ds3231 = nil
		else
			Log ("no i2c pins, not reading ds3231")
			time_read = 0
			haveReadings(#temp)
		end
	else
		do_file("read-"..read_device)
--]]	end
end

-- leave this line at end of the file --
