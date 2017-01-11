-- ESP8266-HTTP Library
-- Written 2014 by Tobias Mädel (t.maedel@alfeld.de)
-- Licensed under MIT
-- Much modified, fixed and enhanced 2015 by Eyal Lebedinsky

local server, port, url = nil, 80, "/upload"
local i = 0

function summary()
	print(("fetched %d files"):format(i))

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

local busy = false
local verbose = false

function getfile(path)
	local size, payloadFound, csize

	local conn = net.createConnection(net.TCP, 0)

	conn:on("connection", function(conn, payload)
		if verbose then
			print(("%2d '%25s'"):format(i, path))
		end
		file.remove(path)
		file.open(path, "w+")
		size = 0
		payloadFound = false

		conn:send(("GET %s/%s HTTP/1.0\r\n Host: %s\r\nConnection: close\r\nAccept-Charset: utf-8\r\nAccept-Encoding: \r\nUser-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\nAccept: */*\r\n\r\n"):
			format(url, path, host))
	end)
	conn:on("receive", function(conn, payload)
		local psize = 0
		if (payloadFound) then
			file.write(payload)
			file.flush()
			psize = #payload
			size = size + psize
		else
			local payloadOffset = string.find(payload, "\r\n\r\n")
			if (payloadOffset) then
				csize, n = string.gsub (payload, ".*Content[-]Length: (%d+).*", "%1")
				if 0 == n then
					print ("no Content-Length")
					csize = 0
				end
				if verbose then
					print(string.sub(payload, 1, payloadOffset + 3))
				end
				file.write(string.sub(payload, payloadOffset + 4))
				file.flush()
				psize = #payload - (payloadOffset + 3)
				size = psize
				payloadFound = true
			end
		end
		if verbose then
			print(("    psize=%4d size=%4d"):format(psize, size))
		end
		payload = nil
		collectgarbage()
	end)
	conn:on("disconnection", function(conn) 
		file.close()
		conn = nil
		if (path) then
			local comment = ""
			if 0+csize ~= size then
				comment = (" expected size %5d"):format(csize)
			end
			print(("%2d %25s %5d%s"):format(i, path, size, comment)) -- prev file
		else
			print ("failed to connect, retrying")
		end
		size, payloadFound = nil, nil
		collectgarbage()

		busy = false
	end)

	conn:connect(port, host)
end

function download(list, dir)
	if #list < 1 then
		print("no files requested")
		return
	end

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
		format(#list, server, port, url))

	tmr.alarm(1, 10, 1, function()
		if (busy) then return end
		if i < #list then
			busy = true
			i = i + 1
			getfile (list[i])
		else
			tmr.stop(1)
			summary()
		end
	end)
end

function my_esp_config()
	return ("esp-%s.lc"):format(string.gsub(string.upper(wifi.sta.getmac()),":","-"))
end
local esp = my_esp_config()

