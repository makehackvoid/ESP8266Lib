local always = true;

local function compile (f)
	if always or nil == file.open (f..".lc") then
		print ("=== compiling "..f..".lua");
		node.compile (f..".lua");
		collectgarbage ();
	else
		file.close ();
	end
end

local function listFiles (title)
	print ("=== files list "..title);
	for k,v in pairs (file.list()) do
		print (string.format ("%20s %4d", k, v));
	end
end

file.remove ("runCount");

listFiles ("before");

compile ("ds18b20");
compile ("getPass");
compile ("getRunCount");
compile ("readTemp");
compile ("doWiFi");
compile ("doMQTT");

-- compile ("init");

listFiles ("after");

-- init.lua: 462
-- ds18b20.lua: 2980
-- ds18b20.lc: 2104
-- getPass.lc: 384
-- pass: 40
-- getPass.lua: 284
-- main.lc: 1928
-- main.lua: 1194
-- getRunCount.lua: 235
-- init.lc: 720
-- readTemp.lua: 248
-- getRunCount.lc: 328
-- readTemp.lc: 364
-- compile.lua: 473
