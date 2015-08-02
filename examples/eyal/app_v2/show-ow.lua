local function show_addr()
	local t = require ("ds18b20")
	t.setup(2)	-- gpio4
	local addrs = t.addrs()
	print("number of devices is " .. #addrs)

	for n = 1,#addrs do
		local addr = addrs[n]
		local s = ""
		for i = 1,8 do
			s = string.format("%s\\%03d",s,addr:byte(i))
		end
		print(string.format("addr[%d] = \"%s\"", n, s))
	end
end

print (string.gsub(string.upper(wifi.sta.getmac()),":","-"))
show_addr()

--[[
	if     mac == "18-FE-34-98-DE-A1" then
		setup_host ("esp-01",  31, gpio0, -60, 1.0170,    0,
			"ds18b20", gpio2)
	elseif mac == "18-FE-34-9C-DA-B6" then
		setup_host ("esp-07",  30, gpio5,  60, 1.0186,    0,
			"ds18b20", gpio4)
	elseif mac == "18-FE-34-A2-6D-6C" then
		setup_host ("esp-07a", 37, gpio5,  60, 1.0173,    0,
			"ds18b20", gpio4)
	elseif mac == "18-FE-34-A2-6D-54" then
		setup_host ("esp-07b", 38, gpio5,  60, 1.0189,    0,
			"ds18b20", gpio4)
	elseif mac == "18-FE-34-A0-5A-A1" then
		setup_host ("esp-12",  35, gpio5,  60, 1.0386,   11,
			"ds18b20", gpio4)
	elseif mac == "18-FE-34-FE-85-3D" then
		setup_host ("esp-12a", 36, gpio5,  60, 1.0346,   12,
			"ds18b20", gpio4)
--	elseif mac == "18-FE-34-xx-xx-xx" then
--		setup_host ("esp-12b", 39, gpio5,  60, 1.04,      0,
--			"ds18b20", gpio4)
	elseif mac == "18-FE-34-A5-DD-11" then
		setup_host ("esp-12e", 40, gpio5,  60, 1.0412,   12,
			"ds18b20", gpio4)
	elseif mac == "18-FE-34-A0-E1-1C" then
		setup_host ("esp-201", 34, gpio5,  60, 1.0409,   12,
			"ds18b20", gpio4)
	elseif mac == "18-FE-34-9B-99-1E" then
		setup_host ("esp-kit", 32, gpio5,  60, 1.0413,    0,
			"ds18b20", gpio4)
	elseif mac == "18-FE-34-98-89-67" then
		setup_host ("nodeMCU", 33, gpio5,  60, 1.0399, 12.3,
			"ds18b20", gpio4)
	end
--]]
