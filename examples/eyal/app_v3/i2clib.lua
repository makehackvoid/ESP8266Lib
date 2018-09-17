--------------------------------------------------------------------------------
-- I2C module for NODEMCU
--------------------------------------------------------------------------------

--== These lines commented to reduce memory size

if nil ~= used then used (...) end

local moduleName = ...
local M = {}
_G[moduleName] = M

local string = string
local bit = bit
local i2c = i2c
local Log = Log

setfenv(1,M)

local id = 0			-- always zero
local dev_addr = nil
local sda, scl = nil, nil

function numToBCD(v)
	v = v%100 - v%1	-- now integer [0...99]
	local lsb = v%10
	return (v-lsb)/10*16 + lsb
end

function BCDtoI8(v, i)
	if nil ~= i then v = string.byte(v, i) end
	local lsb = v%16 - v%1
	return (v-lsb)/16*10 + lsb
end

function numToChar(v)
	return string.char(bit.band(v, 0x0FF))
end

local function setupDevice(dev)
	i2c.start(id)
	local c = i2c.address(id, dev, i2c.TRANSMITTER)
	i2c.stop(id)
	if c then dev_addr = dev end

	return c
end

function setBus(d, c)	-- io indexes: sda, scl
--Log(".setup")
--==	if d == c
--==		or d == nil or d < 0 or d > 12
--==		or c == nil or c < 0 or c > 12
--==	then
--==		---Log("i2c init failed: bad arguments")
--==		return false
--==	end
	sda = d
	scl = c
	i2c.setup(id, sda, scl, i2c.SLOW)

	---Log("init OK")
	return true
end

function setDevice(dev)
--Log(".device")
--==	if sda == nil or scl == nil then
--==		---Log("i2c device failed: i2c not set up")
--==		return false
--==	end

--==	if dev < 0 or dev > 0x0ff then
--==		---Log("i2c device failed: bad arguments")
--==		return false
--==	end

	if not setupDevice(dev) then
		---Log("i2c device failed: no device")
		return false
	end

	---Log("device OK")
	return true
end

function setup(sda, scl, dev)
	return (setBus (sda, scl) and setDevice (dev))
end

-- return data or nil on failure
function read (addr, len)
--Log(".read")
--==	if dev_addr == nil then
--==		---Log("i2c read failed: device not set up")
--==		return nil
--==	end

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
function write (addr, data)
--Log(".write")
--==	if dev_addr == nil then
--==		---Log("i2c read failed: device not set up")
--==		return nil
--==	end

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

function bitSet (reg, flag)
	local val = string.byte(read (reg))
	write (reg, bit.bor (val, flag))
	return val
end

function bitIsSet (reg, flag)
	return bit.band (string.byte(read (reg)), flag) > 0
end

return M
