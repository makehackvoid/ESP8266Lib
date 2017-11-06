local tmr = tmr
time_read = tmr.now()
done_file (time_read)
local mLog = mLog
local function Log (...) if print_log then mLog ("read", unpack(arg)) end end
local function Trace(n, new) mTrace(4, n, new) end Trace (0, true)
used ()
out_bleep()

local function no_ow()
	for n = 1,#ow_addr do
		temp[#temp+1] = 85
	end
end

local function read_ds18b20()
---- save memory ----
	if print_dofile then Log("calling ds18b20") end
	out_bleep()
	start_dofile = tmr.now()
	local t = require ("ds18b20")
	if not t then
		Trace(1)
		Log("required ds18b20 failed")
		no_ow()
		incrementCounter(rtca_failRead);
		return false
	end
	local tm = tmr.now()
	done_file (tm)
	out_bleep()
	time_read = time_read + (tm - start_dofile)	-- adjust time

	if not t.setup (ow_pin) then
		Trace(2)
		Log ("no ds18b20 ow on pin %d", ow_pin)
		no_ow()
		incrementCounter(rtca_failRead);
		return false
	end

	if "" == ow_addr[1] then
		ow_addr = t.addrs()
		Log ("detected %d ds18b20 devices", #ow_addr)
		if 0 == #ow_addr then
			incrementCounter(rtca_failRead);
			return false
		end
	end

local good = 0
	for n = 1,#ow_addr do
		local tC = t.read(ow_addr[n])
		if tC == nil then
			Trace(3)
			tC = 86
			incrementCounter(rtca_failRead);
		else
			good = good + 1
			if tC == "85.0" then
				tC = 87
				incrementCounter(rtca_failRead);
			elseif  tC == 127.9375 then
				tC = 88
				incrementCounter(rtca_failRead);
			end
		end
		temp[#temp+1] = tC
		Log("read[%d]=%.4f", #temp, tC)
	end
Trace(6+good)
	return true
---- save memory ----
--	return false
end

local function read_bme280()
---- save memory ----
	out_bleep()
	local speed = i2c.setup(0, i2c_SDA, i2c_SCL, i2c.SLOW)
	if 0 == speed then
		Trace(6)
		Log ("i2c.setup failed")
		return false
	end
	local dev = bme280.setup(1, 1, 1, 0, 0, 0)
		-- 1, 1, 1		oversampling x1 (read once)
		-- 0			Sleep mode
		-- 0			inactive_duration (not used)
		-- 0			Filter off
	if nil == dev or 0 == dev then
		Trace(4)
		Log ("bme280.setup failed")
		return false
	end
	Log ("found %s", ({"none","bme280", "bmp280"})[dev])

	local T, QFE, H, P = bme280.read(622)
		-- T	temperature in dC
		-- QFE	raw air pressure in hectopascals
		-- H	relative humidity percent
		-- P	sea level equivalent air pressure in hectopascals (QNH)
		-- 622	sensor location altitude in meters

--	local D = 85
--	if H and T then
--		D = bme280.dewpoint(H, T)
--	end

	-- it is possible for *some* values to be nil!
	local failed = 0
	if nil == T then T =  85*100  failed = failed + 1 end
	if nil == P then P = 999*1000 failed = failed + 2 end
	if nil == H then H =   0*1000 failed = failed + 4 end
	if failed > 0 then
		Trace(5)
		Log ("bme280.read failed %d", failed)
	end

--	weather = (" w=T%d.%02d,P%d.%03d,H%d.%03d,D%d.%02d,f%d"):format(
	weather = (" w=T%d.%02d,P%d.%03d,H%d.%03d,f%d"):format(
		T/100,  T%100,
		P/1000, P%1000,
		H/1000, H%1000,
--		D/100,  D%100,
		failed)
	Log (weather)
	temp[#temp+1] = T/100

	bme280.startreadout(1)	-- would prefer 0 but that means 'default' :-(
	return true
---- save memory ----
--	return false
end

local function read_ds3231()
---- save memory ----
	if print_dofile then Log("calling ds3231") end
	out_bleep()
	start_dofile = tmr.now()
	local t = require ("ds3231")
	if not t then
		Log("required ds3231 failed")
		return false
	end
	local tm = tmr.now()
	done_file (tm)
	out_bleep()
	time_read = time_read + (tm - start_dofile)	-- adjust time

	local ret
	if t.setup (i2c_SDA, i2c_SCL) then
		tmr.wdclr()
		temp[#temp+1] = t.getTemp()
		ret = true
	else
		Log ("ds3231 setup failed")
		ret = false
	end

	ds3231, package.loaded["ds3231"] = nil, nil

	return ret
---- save memory ----
--	return false
end

local function have_pin(pin, pin_name, device_name)
	if not pin then
		Log ("no %s pin for %s", pin_name, device_name)
		return false
	end
	if pin < 1  or pin > 13 then	-- see GPIO_PIN_NUM in app/platform/pin_map.h
		Log ("invalid %s pin %d for %s", pin_name, pin, device_name)
		return false
	end
	return true
end

local function have_i2c(device_name)
	return have_pin(i2c_SDA, "SDA", device_name) and
	   have_pin(i2c_SCL, "SCL", device_name)
end

temp = {}

local function doread()
	if not read_device then read_device = "" end
	for device in string.gmatch(read_device, "[^,]+") do
		Log ("reading '%s'", device)
		if device == "ds18b20" then
--			Log ("%s is disabled", device)
---- save memory ---
			if have_pin(ow_pin, "OW", device) then
				if #ow_addr < 1 then
					Log ("no ow devices listed for %s", device)
				else
					read_ds18b20()	-- ignore failure
				end
			end
			read_ds18b20 = nil
			t, ds18b20, package.loaded["ds18b20"] = nil, nil, nil
			device = nil
---- save memory ---
		end
		if device == "bme280" then
--			Log ("%s is disabled", device)
---- save memory ---
			if have_i2c(device) then
				read_bme280()	-- ignore failure
			end
			read_bme280 = nil
			device = nil
---- save memory ----
		end
		if device == "ds3231" then
--			Log ("%s is disabled", device)
---- save memory ---
			if have_i2c(device) then
				read_ds3231()	-- ignore failure
			end
			read_ds3231 = nil
			device = nil
---- save memory ----
		end
		if device then
			local pgm = ("read-%s"):format(device)
			if not pcall (function() do_file(pgm, true) end) then
				Log ("missing or failing '%s'", pgm)
				-- ignore failure
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

	if do_WiFi then do_file ("wifi") end
end

doread()

