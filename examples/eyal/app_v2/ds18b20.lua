--------------------------------------------------------------------------------
-- DS18B20 one wire module for NODEMCU
-- NODEMCU TEAM
-- LICENCE: http://opensource.org/licenses/MIT
-- Vowstar <vowstar@nodemcu.com>
-- 2015/02/14 sza2 <sza2trash@gmail.com> Fix for negative values
--------------------------------------------------------------------------------

-- Set module name as parameter of require
local modname = ...
local M = {}
_G[modname] = M
--------------------------------------------------------------------------------
-- Local used variables
--------------------------------------------------------------------------------
-- DS18B20 dq pin
local pin = nil
-- DS18B20 default pin
local defaultPin = 9
--------------------------------------------------------------------------------
-- Local used modules
--------------------------------------------------------------------------------
-- Table module
local table = table
-- String module
local string = string
-- One wire module
local ow = ow
-- Timer module
local tmr = tmr
-- Limited to local environment
setfenv(1,M)
--------------------------------------------------------------------------------
-- Implementation
--------------------------------------------------------------------------------
C = 0
F = 1
K = 2
function setup(dq)
  pin = dq
  if(pin == nil) then
    pin = defaultPin
  end
  ow.setup(pin)
end

function addrs()
--  setup(pin)
  local tbl = {}
  ow.reset_search(pin)
  repeat
    local addr = ow.search(pin)
    if(addr ~= nil) then
      table.insert(tbl, addr)
    end
    tmr.wdclr()
  until (addr == nil)
  ow.reset_search(pin)
  return tbl
end

function read(addr, unit)
--  setup(pin)
  if(addr == nil) then
    ow.reset_search(pin)
    local count = 0
    repeat
      count = count + 1
      local addr = ow.search(pin)
      tmr.wdclr()
    until((addr ~= nil) or (count > 100))
    ow.reset_search(pin)
    if(addr == nil) then
      return nil
    end
  end
  if (0 ~= ow.crc8(addr)) then
    -- print("CRC is not valid!")
    return nil
  end
  if ((addr:byte(1) ~= 0x10) and (addr:byte(1) ~= 0x28)) then
    -- print("Device family is not recognized.")
    return nil
  end

  ow.reset(pin)
  ow.select(pin, addr)
  ow.write(pin, 0x44, 1)
  ow.reset(pin)
  ow.select(pin, addr)
  ow.write(pin,0xBE,1)

  local data = ow.read_bytes(pin, 9)
  if (0 ~= ow.crc8(data)) then
    -- print ("read failed")
    return nil
  end

  local t = data:byte(1) + data:byte(2) * 256
  if (t > 32767) then
    t = t - 65536
  end
  if(unit == nil or unit == C) then
    t = t * 625
  elseif(unit == F) then
    t = t * 1125 + 320000
  elseif(unit == K) then
    t = t * 625 + 2731500
  else
    -- print ("bad unit")
    return nil
  end
  tmr.wdclr()
  return t / 10000
end

-- Return module table
return M
