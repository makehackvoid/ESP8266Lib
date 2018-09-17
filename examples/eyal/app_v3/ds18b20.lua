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
-- One wire module
local ow = ow
-- Timer module
local tmr = tmr
-- local print = print
-- local string = string
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
	if (nil == pin) then
		pin = defaultPin
	end
	ow.setup(pin)
	return (0 ~= ow.reset(pin))	-- present
end

function addrs()
	local tbl = {}
	ow.reset_search(pin)
	repeat
		local addr = ow.search(pin)
		if (addr ~= nil) then
			local ds = addr:byte(1)
			if (0x28 == ds or 0x10 == ds) then	-- ds18x20
				table.insert(tbl, addr)
			end
		end
		tmr.wdclr()
	until (nil == addr)
	ow.reset_search(pin)
	return tbl
end

local function find_first()
	ow.reset_search(pin)
	local count = 0
	repeat
		count = count + 1
		if (count > 100) then
--			print("no ds18x20 devices found")
			addr = nil
			break
		end
		local addr = ow.search(pin)
		if (nil == addr) then
--			print("no ds18x20 devices found")
			break
		end
		local ds = addr:byte(1)
		if (0x28 ~= ds and 0x10 ~= ds) then		-- not ds18x20
			addr = nil
		end
		tmr.wdclr()
	until (addr ~= nil)
	ow.reset_search(pin)
	return addr
end

local function addr_check(addr)
	if (nil == addr) then
		addr = find_first()
		if (nil == addr) then return nil end
	end
	if (0 ~= ow.crc8(addr)) then
--		print("CRC is not valid")
		return nil
	end
	return addr
end

local function get_scratchpad(addr)
	ow.reset(pin)
	ow.select(pin, addr)
	ow.write(pin,0xBE,1)	-- READ SCRATCHPAD

	local data = ow.read_bytes(pin, 9)
	if (0 ~= ow.crc8(data)) then
--		print("CRC is not valid")
		return nil
	end

	return data
end

local function done_conversion()
	local t = tmr.now() + 750000		-- 750ms limit
	repeat
		local status = ow.read(pin)
		if (tmr.now() > t) then
--			print ("convert timeout")
			return false
		end
		tmr.wdclr()
	until (status ~= 0)
--	print ("converted in "..((tmr.now()-t)/1000).."ms")
	return true
end

function convert(addr, wait)
	ow.reset(pin)
	if (nil == addr) then
		ow.write(pin, 0xCC, 0)	-- SKIP ROM
	else
		ow.select(pin, addr)
	end
	ow.write(pin, 0x44, 1)		-- CONVERT T
	if (wait) then
		if not done_conversion() then return false end
	end
	return true
end

function read(addr, unit, conv, wait)
	addr = addr_check (addr)
	if (nil == addr) then return nil end

	local frac = addr:byte(1)
	if (0x28 == frac) then
		frac = 625	-- DS18B20, 4 fractional bits
	elseif (0x10 == frac) then
		frac = 5000	-- DS18S20, 1 fractional bit
	else
--		print("Device family is not recognized.")
		return nil
	end

--	get last reading
	local data = get_scratchpad(addr)

	if (conv) then
		if (not convert (addr, wait)) then return nil end
	end

	if (nil == data) then return nil end
	local t = data:byte(1) + data:byte(2) * 256
	if (65535 == t) then return nil end	-- 0xffff
	if (t > 32767) then			-- 0x7fff
		t = t - 65536			-- 0x10000
	end
	t = t*frac
	if (nil == unit or C == unit) then
		-- we are good
	elseif (F == unit) then
		t = t*1.8 + 320000
	elseif (K == unit) then
		t = t + 2731500
	else
--		print ("bad unit")
		return nil
	end
	tmr.wdclr()
	return t / 10000
end

function scratchpad_read(addr)
	addr = addr_check (addr)
	if (nil == addr) then return nil end

	return get_scratchpad(addr)
end

function scratchpad_write(addr, Th, Tl, conf)
	addr = addr_check (addr)
	if (nil == addr) then return nil end

	ow.reset(pin)
	ow.select(pin, addr)
	ow.write(pin,0x4E,1)	-- WRITE SCRATCHPAD
	ow.write(pin,Th,1)
	ow.write(pin,Tl,1)
	ow.write(pin,conf,1)
	ow.reset(pin)
end

function scratchpad_copy(addr)
	addr = addr_check (addr)
	if (nil == addr) then return nil end

	ow.reset(pin)
	ow.select(pin, addr)
	ow.write(pin,0x48,1)	-- COPY SCRATCHPAD
end

function scratchpad_recall(addr)
	addr = addr_check (addr)
	if (nil == addr) then return nil end

	ow.reset(pin)
	ow.select(pin, addr)
	ow.write(pin,0xB8,1)	-- RECALL EEPROM
end

-- Return module table
return M
