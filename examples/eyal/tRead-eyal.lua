Server_IP_Address, Server_Port = "192.168.2.7", 1883

gpio0 = 3
gpio2 = 4
gpio4 = 2
gpio5 = 1

ds18b20_pin = nil	-- or gpio4
magic_pin   = gpio5	-- LOW on this pin will disable the program

function read_temp ()
	if nil ~= ds18b20_pin then
		t = require("ds18b20")
		t.setup(ds18b20_pin)

		repeat
			tmr.delay (10000)	-- 10ms
			temp = t.read()
		until temp ~= "85.0" and temp ~= 85
	else
		temp = runCount
	end
	print("Temperature: "..temp.."'C")
end

function testConnection()
	test_count = test_count + 1
	if wifi.sta.getip() == nil then
		if 0 == test_count % 10 then
			print("IP unavaiable after " .. test_count .. " tries")
		end
	else
		tmr.stop(1)
		print("Config done after " .. test_count .. " tries" ..
			", at " .. tmr.now() ..
			", IP is " .. wifi.sta.getip())
		collectgarbage()
		StartProgram()
	end 
end

function StartProgram()
     m = mqtt.Client("clientid", 120)	-- , "user", "password")

     m:on("offline", function(conn)
	print ("offline at " .. tmr.now())
     end)
    
     m:on("connect", function(conn)
	print ("on connect at " .. tmr.now())
     end)
    
     m:connect(Server_IP_Address, Server_Port, 0, function(conn)
	print("connected at " .. tmr.now())
	read_temp ()
	m:publish("testing/temp", "Temperature: "..temp.."'C", 0, 1, function(conn)
		print ("published at " .. tmr.now())
		node.dsleep(5*1000000)	-- 5s
	end)
     end)
end

-- before starting a new test:
--	file.remove ("runCount") ; node.restart()

function getRunCount ()
	local fname = "runCount"

	f = file.open (fname, "r")
	if nil == f then
		runCount = 0
	else
		runCount = file.read()
		file.close()
	end

	runCount = runCount + 1

	file.open (fname, "w")
	file.write (runCount)
	file.close ()

	print ("run " .. runCount)
end

function doit()
	getRunCount ()

	if nil == wifi.sta.getip() then
		print("Setting up WIFI...")
		wifi.setmode(wifi.STATION)
		wifi.sta.config("user", "pass")
		wifi.sta.connect()
	end
	test_count = 0
	tmr.alarm(1, 100, 1, testConnection)	-- 0.1s
end

gpio.mode (magic_pin, gpio.INPUT);
if 0 == gpio.read (magic_pin) then
	print ("aborting by magic")
else
	doit()
end
