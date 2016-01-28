-- ESP8266-HTTP Library
-- Written 2014 by Tobias Mädel (t.maedel@alfeld.de)
-- Licensed under MIT
-- Much modified, fixed and enhanced 2015 by Eyal Lebedinsky

local server, port, url = nil, 80, "/upload"
local filelist
local i = 0

function summary()
	print("fetched "..i.." files")

	local free, used, size = file.fsinfo()
	print(("File system info:\n\tSize %7d Bytes\n\tUsed %7d Bytes\n\tFree %7d Bytes"):
		format(size, used, free))

	local nf, nb = 0, 0
	print ("Files list:")
	for k,v in pairs(file.list()) do
		nf = nf + 1
		nb = nb + v
		print (("%2d %25s %5d"):format(nf, k, v))
	end
	print (("Total %d files, %d bytes"):format(nf, nb))
end

function getfile()
	local path, size, payloadFound

	local conn = net.createConnection(net.TCP, 0)

	conn:on("connection", function(conn, payload)
		i = i + 1
		path = table.remove(filelist, 1)
--		print(("%2d %25s"):format(i, path))
		file.remove(path)
		file.open(path, "w+")
		size = 0
		payloadFound = false

		conn:send("GET "..url.."/"..path.." HTTP/1.0\r\n"..
			"Host: "..host.."\r\n"..
			"Connection: close\r\n"..
			"Accept-Charset: utf-8\r\n"..
			"Accept-Encoding: \r\n"..
			"User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n".. 
			"Accept: */*\r\n\r\n")
	end)
	conn:on("receive", function(conn, payload)
		if (payloadFound) then
			file.write(payload)
			file.flush()
			size = size + #payload
		else
			local payloadOffset = string.find(payload, "\r\n\r\n")
			if (payloadOffset) then
				file.write(string.sub(payload, payloadOffset + 4))
				file.flush()
				size = #payload - (payloadOffset + 3)
				payloadFound = true
			end
		end

		payload = nil
		collectgarbage()
	end)
	conn:on("disconnection", function(conn) 
		file.close()
		conn:close()
		conn = nil
		if (path) then
			print(("%2d %25s %5d"):format(i, path, size))	-- prev file
		else
			print ("failed to connect, retrying")
		end
		path, size = nil, nil

		if #filelist > 0 then
			getfile ()	-- fetch next file
		else
			summary()
		end
	end)

	conn:connect(port, host)
end

function download(list, dir)
	if #list < 1 then
		print("no files requested")
		return
	end

	filelist = list

	local ip, mask, gw = wifi.sta.getip()
	if not ip then
		print ("no IP, please set up networking")
		return
	end
	if 5 ~= wifi.sta.status() then
		print ("no connection, please set up networking")
		return
	end

	server = SERVER and SERVER or gw
	port   = PORT   and PORT   or port
	url = dir and dir or (URL and URL or url)

	print (("Copying %d files from http://%s:%d%s to the esp"):
		format(#filelist, server, port, url))

	getfile ()
end

function my_esp_config()
	local mac = string.gsub(string.upper(wifi.sta.getmac()),":","-")
	return 'esp-' .. mac .. '.lc'
end

