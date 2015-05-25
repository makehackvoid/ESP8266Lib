module = "read-ds3231"
time_dofile = time_dofile + (tmr.now()-start_dofile)
used ()

local function Log(...)
	logMod (module, unpack(arg))
end

local function readTemp()
	Log ("reading")

	start_dofile = tmr.now()
	local t = require ("ds3231")
	time_dofile = time_dofile + (tmr.now()-start_dofile)

	time_read = tmr.now()
	if not t.setup (i2c_SDA, i2c_SCL) then
		Log ("ds3231 setup failed")
		abort = true
		return
	end

	tmr.wdclr()
	temp = t.getTemp()

	time_read = (tmr.now() - time_read) / 1000000
--	Log("temp=%s time=%s",temp , timestamp)
end

if i2c_SDA >= 0 then
	readTemp ()
	t, ds3231, package.loaded["ds3231"] = nil, nil, nil
	-- expecting no more i2c usage
	i2clib, package.loaded["i2clib"] = nil, nil
else
	Log ("not reading temperature")
	temp = nil
	time_read = 0
end

do_file ("wifi")
