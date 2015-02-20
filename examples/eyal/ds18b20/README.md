An example of reading temperature from a ds18b20 and submitting to MQTT
------------

The app reports more than just the temperature as it is used as a test program. It can also print a progress log. It has a few options that are only there for testing.

This version keeps track of the run number (as it sleeps for 3 seconds between runs) by reading the old published data back from the broker. You must, when running it for the first time after flash+load, start it with
<pre>
	resetRunCount = true; use_old_WiFi_setup = false; dofile ("init.lua")
</pre>

First edit `init.lua` to reflect your setup. Instructions at the top section of that program.

Note: Do not reset the esp after the uploads, but go through the following steps before starting with a `dofile()`.

After flashing the firmware (in necessary), start the esp and upload these programs:
<pre>
	init.lua
	doWiFi.lua
	doMQTT.lua
	readTemp.lua
</pre>
If you can compile programs you want to upload this too:
<pre>
	compile.lua
</pre>
You will also need to upload this module from the `nodemcu/nodemcu-firmware/lua_modules` github
<pre>
	ds18b20.lua
</pre>

- If you can compile programs then run
<pre>
	dofile ("compile.lua")
</pre>
- If you want to start counting runs from '1' (rather than continuing from the last run) or this is the very first time you run this, then set
<pre>
	 resetRunCount = true
</pre>
- If you do not have WiFi set up yet then set:
<pre>
	 use_old_WiFi_setup = false
</pre>
- Finally start the program with
<pre>
	dofile ("init.lua")
</pre>

