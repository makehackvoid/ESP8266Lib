--------------------------------------------------------------------------------
-- PCA9555 I2C module for NODEMCU
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
local dev_addr = 0x20		-- PCA9555 i2c id

local INPUT_REG = 0x00
local OUTPUT_REG = 0x02
local POLARITY_REG = 0x04
local CONFIG_REG = 0x06


local function log (msg)
	if true then print (msg) end
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
    log("PCA9555 init failed: bad arguments")
    return nil
  else
    sda = d
    scl = c
  end

  if not setup() then
    log("PCA9555 init failed: no device")
    return nil
  end

  log("PCA9555 init OK")
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

-- get input state
function readPorts()
	local data = readI2C (INPUT_REG, 2)
	if nil == data then return nil end

	return string.byte(data, 1, 2)
end

function readPort0()
	local data = readI2C (INPUT_REG, 1)
	if nil == data then return nil end

	return string.byte(data)
end

function readPort1()
	local data = readI2C (INPUT_REG+1, 1)
	if nil == data then return nil end

	return string.byte(data)
end

-- set output state
function writePorts(data)
	return writeI2C (OUTPUT_REG, data)
end

function writePort0(data)
	return writeI2C (OUTPUT_REG, data)
end

function writePort1(data)
	return writeI2C (OUTPUT_REG+1, data)
end

-- set input polarity as inverse or not
function polarityPorts(data)
	return writeI2C (POLARITY_REG, data)
end

function polarityPort0(data)
	return writeI2C (POLARITY_REG, data)
end

function polarityPort11(data)
	return writeI2C (POLARITY_REG+1, data)
end

-- set pin configuration as in or out
function configPorts(data)
	return writeI2C (CONFIG_REG, data)
end

function configPort0(data)
	return writeI2C (CONFIG_REG, data)
end

function configPort1(data)
	return writeI2C (CONFIG_REG+1, data)
end

return M
