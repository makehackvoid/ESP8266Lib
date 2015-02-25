--------------------------------------------------------------------------------
-- DS3231 I2C module for NODEMCU
-- NODEMCU TEAM
-- LICENCE: http://opensource.org/licenses/MIT
-- Tobie Booth <tbooth@hindbra.in>
--------------------------------------------------------------------------------

local moduleName = ...
local M = {}
_G[moduleName] = M

-- Default value for i2c communication
local id = 0

--device address
local dev_addr = 0x68

local function int (val)
	return bit.bor(val, 0)
end

local function decToBcd(val)
  return(int(val/10)*16 + (val%10))
end

local function bcdToDec(val)
  return(int(val/16)*10 + (val%16))
end

-- initialize i2c
--parameters:
--d: sda
--l: scl
function M.init(d, l)
  if (d ~= nil) and (l ~= nil) and (d >= 0) and (d <= 11) and (l >= 0) and ( l <= 11) and (d ~= l) then
    sda = d
    scl = l
  else
    print("iic config failed!") return nil
  end
    print("init done")
    i2c.setup(id, sda, scl, i2c.SLOW)
end

--get time from DS3231
function M.getTime()
  i2c.start(id)
  i2c.address(id, dev_addr, i2c.TRANSMITTER)
  i2c.write(id, 0x00)
  i2c.stop(id)
  i2c.start(id)
  i2c.address(id, dev_addr, i2c.RECEIVER)
  local c=i2c.read(id, 7)
  i2c.stop(id)

  local month = tonumber(string.byte(c, 6))

  return bcdToDec(tonumber(string.byte(c, 1))),
  bcdToDec(tonumber(string.byte(c, 2))),
  bcdToDec(tonumber(string.byte(c, 3))),
  bcdToDec(tonumber(string.byte(c, 4))),
  bcdToDec(tonumber(string.byte(c, 5))),
  bcdToDec(bit.band (month, 0x1F)),
  bcdToDec(tonumber(string.byte(c, 7))) + 2000 + 100*int(month/128)
end

--set time for DS3231
function M.setTime(second, minute, hour, day, date, month, year)
  if year >= 2000 then
	year = year - 2000
  end
  if year >= 100 then
	year = year - 100
	month = month + 80
  end

  i2c.start(id)
  i2c.address(id, dev_addr, i2c.TRANSMITTER)
  i2c.write(id, 0x00)
  i2c.write(id, decToBcd(second))
  i2c.write(id, decToBcd(minute))
  i2c.write(id, decToBcd(hour))
  i2c.write(id, decToBcd(day))
  i2c.write(id, decToBcd(date))
  i2c.write(id, decToBcd(month))
  i2c.write(id, decToBcd(year))
  i2c.stop(id)
end

function M.getTemp()
  i2c.start(id)
  i2c.address(id, dev_addr, i2c.TRANSMITTER)
  i2c.write(id, 0x11)
  i2c.stop(id)
  i2c.start(id)
  i2c.address(id, dev_addr, i2c.RECEIVER)
  local t=i2c.read(id, 2)
  i2c.stop(id)
  return tonumber(string.byte(t, 1)) + tonumber(string.byte(t, 2))/64
end

return M
