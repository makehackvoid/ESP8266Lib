-- usage: dofile ("compile.lua")

print ("used " .. collectgarbage("count")*1024)

local always = true;

local function compile (f)
	if always or nil == file.open (f..".lc") then
		print ("=== compiling "..f..".lua");
		node.compile (f..".lua");
		collectgarbage ();
		print ("used " .. collectgarbage("count")*1024)
	else
		file.close ();
	end
end

print ("used " .. collectgarbage("count")*1024)

compile ("compile");
compile ("main");
compile ("config");
compile ("doRead");
compile ("i2clib");
compile ("doWiFi");
compile ("doMQTT");

print ("now run: node.compile ('ds3231.lua')")

--compile ("ds18b20");

print ("used " .. collectgarbage("count")*1024)

--resetRunCount = true
if nil == reboot then
	node.restart()
end
