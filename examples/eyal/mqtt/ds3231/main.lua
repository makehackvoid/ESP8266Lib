print ((tmr.now()/1000000) .. " main   used " .. collectgarbage("count")*1024)

abort = false

dofile ("config.lc")		-- no lua_type yet
used ("main +config")
if not abort then
	dofile ("doRead"..lua_type)
	used ("main +doRead")
	if not abort then
		dofile ("doWiFi"..lua_type)
	end
end
---used ("end")
