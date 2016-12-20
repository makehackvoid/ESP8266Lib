local tmr = tmr
done_file (tmr.now())
local mLog = mLog
local function Log (...) if print_log then mLog ("read", unpack(arg)) end end
local function Trace(n) mTrace(4, n) end Trace (0)
used ()
out_bleep()

local function read_ds18b20()
	if print_stats then Log("calling ds18b20") end
	start_dofile = tmr.now()
	local t = require ("ds18b20")
	local tm = tmr.now()
	done_file (tm)
	out_bleep()
	time_read = time_read + (tm - start_dofile)	-- adjust time

	if not t.setup (ow_pin) then
		Log ("no ow on pin %d", ow_pin)
		return
	end

	if "" == ow_addr[1] then
		ow_addr = t.addrs()
		Log ("detected %d devices", #ow_addr)
		if 0 == #ow_addr then
			return
		end
	end

	for n = 1,#ow_addr do
		local tC = t.read(ow_addr[n])
		if tC == nil or tC == "85.0" then
			tC = 85
		end
		temp[#temp+1] = tC
	end
end

--[[local function read_ds3231()
	if print_stats then Log("calling ds3231") end
	start_dofile = tmr.now()
	local t = require ("ds3231")
	local tm = tmr.now()
	done_file (tm)
	out_bleep()
	time_read = time_read + (tm - start_dofile)	-- adjust time

	if not t.setup (i2c_SDA, i2c_SCL) then
		Log ("ds3231 setup failed")
	else
		tmr.wdclr()
		temp[#temp+1] = t.getTemp()
	end
end--]]

local function read_bme280()
	out_bleep()
	local dev = bme280.init(i2c_SDA, i2c_SCL, 1, 1, 1, 0, 0, 0)
		-- i2c_SDA,i2c_SCL	i2c pins
		-- 1, 1, 1		oversampling ×1 (read once)
		-- 0			Sleep mode
		-- 0			inactive_duration (not used)
		-- 0			Filter off
	if nil == dev or 0 == dev then
		Log ("bme280.init failed")
		return
	end
	Log ("found %s", ({"none","bme280", "bmp280"})[dev])

	local T, QFE, H, P = bme280.read(622)	-- my property's altitude is 622m
		-- QFE	raw air pressure in hectopascals
		-- P	sea level equivalent air pressure in hectopascals (QNH)
		-- 622	sensor location altitude in meters
	if nil == T then
		Log ("bme280.read failed")
		T, P, H = 8500, 0, 0
	end
	weather = (" w=T%d.%02d,P%d.%03d,H%d.%03d"):format(
		T/100,  T%100,
		P/1000, P%1000,
		H/1000, H%1000)
	Log (weather)
	temp[#temp+1] = T/100

	bme280.startreadout(1)	-- would prefer 0 but that means 'default' :-(
end

temp = {}
time_read = tmr.now()

if not read_device then read_device = "" end
for device in string.gmatch(read_device, "[^,]+") do
	Log ("reading '%s'", device)
	if device == "ds18b20" then
		if ow_pin < 0 then
			Log ("no ow pin, not reading ds18b20")
		elseif #ow_addr < 1 then
			Log ("no ow listed")
		else
			read_ds18b20()
		end
		read_ds18b20 = nil
		t, ds18b20, package.loaded["ds18b20"] = nil, nil, nil
		device = nil
	end
--[[
	if device == "ds3231" then
		if i2c_SDA >= 0 and i2c_SCL >= 0 then
			read_ds3231()
		else
			Log ("no i2c pins, not reading ds3231")
		end
		read_ds3231 = nil
		ds3231, package.loaded["ds3231"] = nil, nil
		device = nil
	end
--]]
	if device == "bme280" then
		if i2c_SDA >= 0 and i2c_SCL >= 0 then
			read_bme280()
		else
			Log ("no i2c pins, not reading bme280")
		end
		read_bme280 = nil
		device = nil
	end

	if device then
		if not pcall (function() do_file("read-"..device, true) end) then
			print ("missing read-"..device)
		end
		device = nil
	end
end

time_read = tmr.now() - time_read

if print_log and #temp > 0 then
	local tCs = ""
	local tSep = ""
	for n = 1,#temp do
		tCs = ("%s%s%.4f"):format(tCs, tSep, (temp[n] or 0))
		tSep = ","
	end
	Log ("have Reading %s", tCs)
end

if not abort and do_WiFi then do_file ("wifi") end

