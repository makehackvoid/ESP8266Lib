function realMain()
	Server_IP_Address, Server_Port = "192.168.2.7", 1883;

	gpio0 = 3;
	gpio2 = 4;
	gpio4 = 2;
	gpio5 = 1;

	ds18b20_pin = gpio4;	-- nil or gpio4
	magic_pin   = gpio5;	-- LOW on this pin will disable the program

	gpio.mode (magic_pin, gpio.INPUT);
	if 0 == gpio.read (magic_pin) then
		print ("aborting by magic");
	else
		dofile ("getRunCount.lua");
		dofile ("readTemp.lua");
		dofile ("main.lua");

		print ("program end");
	end
end

tmr.alarm(1, 10, 0, realMain);
