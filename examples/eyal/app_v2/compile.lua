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
	used ("compile start")

	local t = 0
	for k,v in pairs(file.list()) do
		t = t + v
		print (string.format("%20s %5d", k, v))
		local i,j = string.find (k, ".lua")
		if i then
			f = string.sub (k, 1, i-1)
			if not (f == "compile" or
				f == "init" or
				f == "i") then
				compile (f)
			end
		end
	end
	print (string.format("%20s %5d","TOTAL",t))

	used("compile end")
	if nil ~= reboot then
		node.restart()
	end

	-- runCount = 1
end

tmr.alarm (1, 1, 0, compileAll)
--compileAll()
