--------------------------------------------------------------------------------
-- DS3231 I2C module for NODEMCU
--------------------------------------------------------------------------------

--== These lines commented to reduce memory size

local moduleName = ...
local M = {}
_G[moduleName] = M

local bit = bit
local string = string
local i2clib = require("i2clib")

setfenv(1,M)

local id = 0			-- always zero
local dev_addr = 0x68		-- DS3231 i2c id

local CALENDAR_REG = 0x00	-- to 0x06
local CALENDAR_YEAR = 2000	-- assumed base century

local ALARM1_REG = 0x08		-- 08: sec, min, hour, day, dow, mon ,year :0A
local ALARM2_REG = 0x0B		-- 0B: min, hour, day :0D

local CONTROL_REG = 0x0E
local CONTROL_A1IE = 0x01	-- Alarm 1 Interrupt Enable
local CONTROL_A2IE = 0x02	-- Alarm 2 Interrupt Enable
local CONTROL_CONV = 0x20	-- start conversion

local STATUS_REG = 0x0F
local STATUS_BUSY = 0x04	-- converter busy

--local AGING_REG = 0x10		-- not used yet

local TEMP_REG = 0x11		-- and 0x12, temperature 8.2 bits

function setup(sda, scl)
	return i2clib.setup (sda, scl, dev_addr)
end

-- get time from DS3231
function getTime()
	local d = i2clib.read (CALENDAR_REG, 7)
--==	if nil == d then return nil end

	local hour = string.byte(d, 3)
	local hour_pm = bit.band (hour,0x60)
	if hour_pm >= 0x40 then	-- AM/PM mode
		if hour_pm == 0x60 then	-- it is PM
			hour_pm = 12
		else
			hour_pm = 0	-- it is AM
		end
		hour = bit.band (hour, 0x1F)
	else
		hour_pm = 0
	end

	local month = string.byte(d, 6)

	return 
		i2clib.BCDtoI8(d, 1),			-- second
		i2clib.BCDtoI8(d, 2),			-- minute
		i2clib.BCDtoI8(hour) + hour_pm,		-- hour
		i2clib.BCDtoI8(d, 4),			-- day of week
		i2clib.BCDtoI8(d, 5),			-- day
		i2clib.BCDtoI8(bit.band (month, 0x1F)),	-- month
		i2clib.BCDtoI8(d, 7)			-- year
			+ CALENDAR_YEAR + 100*bit.rshift(month, 7)
end

-- set time for DS3231
function setTime(second, minute, hour, dow, day, month, year)
-- validate arguments?
	if year >= CALENDAR_YEAR then
		year = year - CALENDAR_YEAR
	end
--==	if year >= 100 then
--==		year = year - 100
--==		month = month + 80	-- set century bit
--==	end

	return 7 == i2clib.write (CALENDAR_REG,
		string.char (
			i2clib.numToBCD(second),
			i2clib.numToBCD(minute),
			i2clib.numToBCD(hour),	-- always clear AM/PM flag
			i2clib.numToBCD(dow),
			i2clib.numToBCD(day),
			i2clib.numToBCD(month),
			i2clib.numToBCD(year)))
end

-- get the latest reading (done every 64 seconds)
function getTemp()
	local d = i2clib.read (TEMP_REG, 2)
--==	if nil == d then return nil end

	local msb, lsb = string.byte(d, 1, 2)
	local temp = msb + bit.rshift (lsb, 6)/4	-- unsigned 10-bit
	if msb >= 0x080 then
		temp = 256 - temp			-- 8-bit two's complement
	end
	return temp
end

local function isBusy()
	return i2clib.bitIsSet (STATUS_REG, STATUS_BUSY)
end

-- make a fresh reading
function getTempNow()
	if not isBusy() then
		i2clib.bitSet (CONTROL_REG, CONTROL_CONV)
		repeat until isBusy()
	end
	repeat until not isBusy()

	return getTemp()
end

local A_r = {ALARM1_REG, ALARM2_REG}
local A_f = {CONTROL_A1IE, CONTROL_A2IE}
local A_l = {4, 3}	-- length

local function alarmIsUsed(a)
	return i2clib.bitIsSet (CONTROL_REG, A_f[a])
end

function getAlarm(a)
--==	if alarmIsUsed (a) then return nil end

	local l = A_l[a]	-- length

	local d = i2clib.read (A_r[a], l)
--==	if d == nil then return nil end

	local v = 0
	for i = 1, l do
		v = bit.lshift(v, 8) + string.byte(d, i)
	end

	return v
end

function setAlarm(a, v)
--==	if alarmIsUsed (a) then return false end

	local l = A_l[a]	-- length
	local d = ""
	for i = 1, l do
		d = i2clib.numToChar(v) .. d
		v = bit.rshift (v, 8)
	end

	return l == i2clib.write (A_r[a], d)
end

return M
