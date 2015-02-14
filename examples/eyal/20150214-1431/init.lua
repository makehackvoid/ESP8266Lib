-- before starting a new test:
--	file.remove ("runCount") ; node.restart()

-- uart.setup (0, 115200, 8, 0, 1, 1);

Broker_IP_Address, Broker_Port = "192.168.2.7", 1883;

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
	dofile ("getRunCount.lc");
	dofile ("readTemp.lc");
	dofile ("doWiFi.lc");

	print ("program end");
end
