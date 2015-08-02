--------------------------------------------------------------------------------
-- DS3231 I2C module for NODEMCU (temperature only)
--------------------------------------------------------------------------------

if nil ~= used then used (...) end

local moduleName = ...
local M = {}
_G[moduleName] = M

local bit = bit
local string = string
local Log = Log
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

-- get the latest reading (done every 64 seconds)
function getTemp()
	local d = i2clib.read (TEMP_REG, 2)
	if nil == d then return nil end

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

return M
