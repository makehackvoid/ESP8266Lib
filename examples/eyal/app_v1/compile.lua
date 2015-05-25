-- usage: dofile ("compile.lua")

local function Log (message, ...)
	local t = tmr.now()/1000000
	if 0 == #arg then
		print (t, message)
	else
		print (t, string.format (message, unpack(arg)))
	end
end

local function used (title)
	Log ("%s: used %d, heap=%d",
		title, collectgarbage("count")*1024, node.heap())
end

used("start")

local always = true

local function compile (f)
	if always or nil == file.open (f..".lc") then
		Log ("=== compiling %s.lua", f)
		node.compile (f..".lua")
		used("compile")
	else
		file.close ()
	end
	collectgarbage()
end

local function compileAll ()
	used("compile start")

--	compile ("ds3231")
--	compile ("i2clib")
--	compile ("read-ds3231")

	compile ("ds18b20")
	compile ("read-ds18b20")

	compile ("compile")
	compile ("funcs")
	compile ("main")
	compile ("wifi")
	compile ("first")
	compile ("save-tcp")
	compile ("save-udp")

	used("compile end")
	if nil ~= reboot then
		node.restart()
	end

	-- runCount = 1
end

tmr.alarm (1, 1, 0, compileAll)
--compileAll()
