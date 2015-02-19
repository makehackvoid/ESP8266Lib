This is an example of an application to read the temperature from a ds18b20 and submit to an MQTT broker.

The app reports more than just the temperature as it is used as a test program. It can also print a progress log.

This version keeps track of the run number (as it sleeps for 6 seconds between runs) by reading the old one back from the broker. You must, when running it for the first time, run it as
<pre>
	resetRunCount = true ; dofile ("init.lua")
</pre>

This program needs a firmware that can compile. If you do not have it then change all the `dofile()`s to run the `.lua` rather than the `.lc`.

First edit `init.lua` to reflect your setup. See the top of that program.

Upload these programs:
<pre>
	init.lua
	doWiFi.lua
	doMQTT.lua
	readTemp.lua
</pre>
If you can compile programs you want this:
<pre>
	compile.lua
</pre>
You will also need to upload this module from the `nodemcu-firmware/lua_modules` github
<pre>
	ds18b20.lua
</pre>

Now start your esp.
- If you can compile then do this:
<pre>
	dofile ("compile.lua")
</pre>
- If you want to start counting runs from '1' (rather than continuing from the last run) then set
<pre>
	 resetRunCount = true
</pre>
- Finally start the program with
<pre>
	dofile ("init.lua")
</pre>

