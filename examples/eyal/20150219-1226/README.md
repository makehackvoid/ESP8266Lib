This is an example of an application to read the temperature from a ds18b20 and submit to an MQTT broker.

The app reports more than just the temperature as it is used as a test program. It can also print a progress log.

This version keeps track of the run number (as it sleeps for 6 seconds between runs) by reading the old one back from the broker. You must, when running it for the first time, run it as
	resetRunCount = true ; dofile ("init.lua")

This program needs a firmware that can compile. If you do not have it then change all the `dofile()`s to run the `.lua` rather than the `.lc`.

First edit `init.lua` to reflect your setup. See the top of that program.

Upload these programs:
	init.lua
	doWiFi.lua
	doMQTT.lua
	readTemp.lua
If you can compile programs you want this:
	compile.lua
You will also need to upload this module from the `nodemcu-firmware/lua_modules` github
	ds18b20.lua

Now start your esp.
- If you can compile then do this:
	dofile ("compile.lua")
- If you want to start counting runs from '1' (rather than continuing from the last run) then set
	 resetRunCount = true
- Finally start the program with
	dofile ("init.lua")

