-- Based on: https://github.com/hessch/lm75lib

-- lm75.lua - NodeMCU Library for LM75 i2c temperature sensors

local moduleName = ...
local M = {}
_G[moduleName] = M

local bit = bit
local string = string
local i2c = i2c
local print = print

-- Limited to local environment
setfenv(1,M)

-- Default value for i2c communication
local id = 0

-- device address
local dev_addr = 0x48

-- temperature register
local temp_reg = 0

local function log (msg)
	if false then print (msg) end
end

local function setup (sda, scl)
	i2c.setup (id, sda, scl, i2c.SLOW)

-- validate device address
	i2c.start (id)
	local c = i2c.address (id, dev_addr, i2c.TRANSMITTER)
	i2c.stop (id)
	return c
end

function init (d, c)
	if d == nil or c == nil or d < 0 or d > 12 or c < 0 or c > 12 or d == c then
		log ("lm75 init failed: bad arguments")
		return nil
	end
	if not setup (d, c) then
		log ("lm75 init failed: no device")
		return nil
	end
	log ("lm75 init OK")
	return true
end

function strTemp ()
	i2c.start (id)
	local t = i2c.address (id, dev_addr, i2c.TRANSMITTER)
	if t then
		i2c.write (id, temp_reg)
	end
	i2c.stop (id)
	if not t then return nil end

	i2c.start (id)
	local data = nil
	if i2c.address (id, dev_addr, i2c.RECEIVER) then
		data = i2c.read (id, 2)
	end
	i2c.stop(id)
	if nil == data then return nil end

	local msb, lsb = string.byte (data, 1, 2)
	if msb > 127 then msb = msb - 255 end
	lsb = bit.band (bit.rshift (lsb, 5), 7)	-- or ', 7), 1)'
	return string.format ("%d.%d", msb, lsb)
end

function intTemp ()
	local str = strTemp ()
	if nil == str then return nil end
	return tonumber (str)
end

return M
