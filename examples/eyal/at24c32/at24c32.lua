--------------------------------------------------------------------------------
-- AT24C32 I2C module for NODEMCU
--------------------------------------------------------------------------------

local moduleName = ...
local M = {}
_G[moduleName] = M

local bit = bit
local i2c = i2c
local tmr = tmr
local string = string
local print = print
setfenv(1,M)

local id = 0			-- always zero
local dev_addr = 0x57		-- AT24Cxx i2c id
local lastWrite = 0
local tWR = 10*1000

local function log (msg)
	if false then print (msg) end
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
		log(moduleName .. " init failed: bad arguments")
		return nil
	else
		sda = d
		scl = c
	end

	if not setup() then
		log(moduleName .. " init failed: no device")
		return nil
	end

	lastWrite = tmr.now() - tWR
	log(moduleName .. " init OK")
end

-- return number of bytes written
local function writeI2C (addr, data)
	if addr == nil or addr < 0 then
		log(moduleName .. " bad len");
		return 0
	end

-- must wait tWR (10ms) after write/stop before next start
if false then
	-- method 1: sleep until 10ms passed on timer.
	local delay =  (lastWrite + tWR) - tmr.now()
	if delay > 0 then tmr.delay (delay) end

	i2c.start(id)
	if not i2c.address(id, dev_addr, i2c.TRANSMITTER) then
		log(moduleName .. " address(TRANSMITTER) failed");
		return 0
	end
else
	-- method 2: as above but try earlier anyway
	repeat
		i2c.start(id)
		if i2c.address(id, dev_addr, i2c.TRANSMITTER) then break end
		i2c.stop(id)

		if tmr.now() - lastWrite > tWR then
			log(moduleName .. " address(TRANSMITTER) failed");
			return 0
		end
	until false
end

	if i2c.write(id, string.char (
				bit.rshift (addr, 8),
				bit.band (addr, 0x0FF))) ~= 2 then
		log(moduleName .. " address write failed");
		i2c.stop(id)
		return 0
	end

	if data == nil then
		return 1	-- no stop, used to set up Randon Read
	end

	local len = i2c.write(id, data)
	i2c.stop(id)
	lastWrite = tmr.now()
	return len
end

-- return data read
local function readI2C (len)
	if len == nil or len <= 0 then
		log(moduleName .. " bad len");
		return nil
	end

	i2c.start(id)
	if not i2c.address(id, dev_addr, i2c.RECEIVER) then
		log(moduleName .. " address(RECEIVER) failed");
		i2c.stop(id)
		return nil
	end


	local data = i2c.read(id, len)
	i2c.stop(id)
	return data
end

-- Handle: Byte Write and Page Write
function write (addr, data)
	if addr == nil or data == nil then
		log(moduleName .. " bad arguments");
		return 0
	end

	return writeI2C (addr, data)
end

-- Handle: Current Address Read, Random Read, and Sequential Read
-- addr == nil means Current Address Read
-- len == nil same as len == 1
function read (addr, len)
	if addr == nil then
		if data == nil then
			log(moduleName .. " all arguments arre nil");
			return nil
		end
	elseif addr < 0 then
		log(moduleName .. " bad address");
		return nil
	end

	if len == nil then
		len = 1
	elseif len < 0 then
		log(moduleName .. " bad length");
		return nil
	end

	if addr ~= nil then
		if writeI2C (addr) ~= 1 then
			log(moduleName .. " address write failed");
			return nil
		end
	end

	return readI2C (len)
end

return M
