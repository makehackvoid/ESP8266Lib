--------------------------------------------------------------------------------
-- DS3231 I2C module for NODEMCU (read temperature only)
--------------------------------------------------------------------------------

if nil ~= used then used (...) end

local moduleName = ...
local M = {}
_G[moduleName] = M

local string = string
local i2clib = require("i2clib")

setfenv(1,M)

local id = 0			-- always zero
local dev_addr = 0x68		-- DS3231 i2c id

local CONTROL_REG = 0x0E
local CONTROL_CONV = 0x20	-- start conversion

local STATUS_REG = 0x0F
local STATUS_BUSY = 0x04	-- converter busy

local TEMP_REG = 0x11		-- and 0x12, temperature 8.2 bits

function setup(sda, scl)
	return i2clib.setup (sda, scl, dev_addr)
end

-- get the latest reading (done every 64 seconds)
function getTemp()
	local d = i2clib.read (TEMP_REG, 2)
	if nil == d then return nil end

	local msb, lsb = string.byte(d, 1, 2)
	local temp = msb + (lsb-lsb%64)/256
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
