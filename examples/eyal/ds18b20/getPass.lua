local function readLine()
	local line = file.readline ()
	return string.sub (line, 1, #line-1)
end

if nil == file.open ("pass", "r") then
	print ("missing password file")
else
	ssid = readLine()
	pass = readLine()
	file.close()
	-- print ("ssid='" .. ssid .. "' pass='" .. pass .. "'")
end
