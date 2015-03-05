--------------------------------------------------------------------------------
-- DS3231 I2C module for NODEMCU
-- NODEMCU TEAM
-- LICENCE: http://opensource.org/licenses/MIT
-- Tobie Booth <tbooth@hindbra.in>
--------------------------------------------------------------------------------

local moduleName = ...
local M = {}
_G[moduleName] = M

local bit = bit
local string = string
local i2c = i2c
local print = print
local tonumber = tonumber
setfenv(1,M)

local id = 0			-- always zero
local dev_addr = 0x68		-- DS3231 i2c id

local CALENDAR_REG = 0x00	-- to 0x06

local CONROL_REG = 0x0E
local CONTROL_CONV = 0x20

local STATUS_REG = 0x0F
local STATUS_BUSY = 0x04

local AGING_REG = 0x10		-- not used yet

local TEMP_REG = 0x11		-- and 0x12

local function log (msg)
	if false then print (msg) end
end

local function int (val)
	return bit.bor(val, 0)
end

local function decToBcd(val)
  return(int(val/10)*16 + (val%10))
end

local function bcdToDec(val)
  return(int(val/16)*10 + (val%16))
end

local function setup()
  i2c.setup(id, sda, scl, i2c.SLOW)
  i2c.start(id)
  local c = i2c.address(id, dev_addr, i2c.TRANSMITTER)
  i2c.stop(id)
  return c
end

function init(d, c)	-- io indexes: sda, scl
  if d == nil or c == nil or d < 0 or d > 12 or c < 0 or c > 12 or d == c then
    log("ds3231 init failed: bad arguments")
    return nil
  else
    sda = d
    scl = c
  end

  if not setup() then
    log("ds3231 init failed: no device")
    return nil
  end

  log("ds3231 init OK")
end

-- return data or nil on failure
local function readI2C (addr, len)
  i2c.start(id)
  local c = i2c.address(id, dev_addr, i2c.TRANSMITTER)
  if c then i2c.write(id, addr) end
  i2c.stop(id)
  if not c then return nil end

  i2c.start(id)
  c = i2c.address(id, dev_addr, i2c.RECEIVER)
  local data = nil
  if c then
	if nil == len then len = 1 end
	data = i2c.read(id, len)
  end
  i2c.stop(id)

  return data
end

-- return number of bytes read
local function writeI2C (addr, data)
  i2c.start(id)
  local c = i2c.address(id, dev_addr, i2c.TRANSMITTER)
  local len = 0
  if c then
    len = i2c.write(id, addr)
    if len > 0 then len = i2c.write(id, data) end
  end
  i2c.stop(id)

  return len
end

-- get time from DS3231
function getTime()
  local data = readI2C (CALENDAR_REG, 7)
  if nil == data then return nil end

  local hour = string.byte(data, 3)
  local hour_pm = hour >= 0x40
  if hour_pm then		-- AM/PM used
	if hour >= 0x60 then	-- it is PM
		hour_pm = 12
	else
		hour_pm = 0	-- it is AM
	end
	hour = bit.band (hour, 0x1F)
  else
	hour_pm = 0
  end

  local month = tonumber(string.byte(data, 6))

  return 
    bcdToDec(tonumber(string.byte(data, 1))),	-- second
    bcdToDec(tonumber(string.byte(data, 2))),	-- minute
    bcdToDec(tonumber(hour)) + hour_pm,		-- hour
    bcdToDec(tonumber(string.byte(data, 4))),	-- day of week
    bcdToDec(tonumber(string.byte(data, 5))),	-- day
    bcdToDec(bit.band (month, 0x1F)),		-- month
    bcdToDec(tonumber(string.byte(data, 7))) + 2000 + 100*int(month/128)
end

-- set time for DS3231
function setTime(second, minute, hour, dow, day, month, year)
-- validate arguments?
  if year >= 2000 then
	year = year - 2000
  end
  if year >= 100 then
	year = year - 100
	month = month + 80
  end

  local len = writeI2C (CALENDAR_REG,
    string.char (
      decToBcd(second),
      decToBcd(minute),
      decToBcd(hour),		-- always clear AM/PM flag
      decToBcd(dow),
      decToBcd(day),
      decToBcd(month),
      decToBcd(year)))

  return 8 == len
end

-- get the latest reading (done every 64 seconds)
function getTemp()
	local data = readI2C (TEMP_REG, 2)
	if nil == data then return nil end

	local msb, lsb = string.byte(data, 1, 2)
	local temp = msb + bit.rshift (lsb, 6)/4	-- unsigned 10-bit
	if bit.band (msb, 0x80) ~= 0 then
		temp = 256 - temp			-- 8-bit two's complement
	end
	return temp
end

local function isBusy()
	local status = readI2C (STATUS_REG)
	return bit.band (string.byte(status), STATUS_BUSY) == STATUS_BUSY
end

-- make a fresh reading
function getTempNow()
	if not isBusy() then
		local control = readI2C (CONROL_REG)
		writeI2C (CONROL_REG, bit.bor (string.byte(control), CONTROL_CONV))
		repeat until isBusy()
	end
	repeat until not isBusy()

	return getTemp()
end

return M
