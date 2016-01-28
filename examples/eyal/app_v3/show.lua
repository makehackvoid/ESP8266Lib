local function show_addr()
	local t = require ("ds18b20")
	t.setup(2)	-- gpio4
	local addrs = t.addrs()
	print("number of devices is " .. #addrs)

	for n = 1,#addrs do
		local addr = addrs[n]
		local s = ""
		for i = 1,8 do
			s = ("%s\\%03d"):format (s, addr:byte(i))
		end
		print(("addr[%d] = \"%s\""):format(n, s))
	end
end

print (string.gsub(string.upper(wifi.sta.getmac()),":","-"))
show_addr()
