-- Display some stats of the module, including the list of attached one-wire modules

local gpio4 = 2
local function show_addr()
	local t = require ("ds18b20")
	local ow_pin = ow_pin or gpio4
	print("using pin " .. ow_pin)
	t.setup(ow_pin)
	local addrs = t.addrs()
	print("number of devices is " .. #addrs)

	for n = 1,#addrs do
		local addr = addrs[n]

		local s_lua = ""
		local s_c = ""
		local s_c_sep = ""
		for i = 1,8 do
			s_lua = ("%s\\%03d"):format (s_lua, addr:byte(i))
			s_c   = ("%s%s %3d") :format (s_c, s_c_sep, addr:byte(i))
			s_c_sep = ","
		end
		print(("addr[%d] = \"%s\","):format(n, s_lua))
		print(("addr[%d] = {%s},") :format(n, s_c))
	end
end

print("flashsize "..node.flashsize())
print("info "..string.format("%x %x %x %x %x %x %x %x", node.info()))
print("info "..string.format("%d %d %d %d %d %d %d %d", node.info()))
print("STA MAC "..wifi.sta.getmac())
print("AP  MAC "..wifi.ap.getmac())

print ("esp-"..string.gsub(string.upper(wifi.sta.getmac()),":","-")..".lua")
show_addr()

