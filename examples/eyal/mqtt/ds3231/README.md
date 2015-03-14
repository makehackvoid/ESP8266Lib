An example of reading temperature from a ds3231 and submitting to MQTT
------------

The app reports more than just the temperature as it is used as a test program. It can also print a progress log. It has a few options that are only there for testing.

This version can keep track of the run number between runs by reading the old published data back from the broker. For this you must, when running it for the first time after flash+load, start it with
<pre>
	runCount = 1; use_old_WiFi_setup = false; dofile ("main.lua")
</pre>
It can slso store the run number on the ds3231 itself if you set.
<pre>
	abuseAlarm = true
</pre>
which is the default.

First edit `config.lua` to reflect your setup. Also, adjust `init.lua` to use `.lc` or `.lua` as required.

Note: Do not reset the esp after the uploads, but go through the following steps before running it.

After flashing the firmware (if necessary), start the esp and upload these programs:
<pre>
	main.lua
	config.lua
	doRead.lua
	ds3231.lua
	i2clib.lua
	doMQTT.lua
	doWiFi.lua
</pre>
If you can compile programs (this is the default) you want to upload this too:
<pre>
	compile.lua
</pre>
and run it:
<pre>
	dofile ("compile.lua")
</pre>
- If you want to start counting runs from '1' (rather than continuing from the last run) or this is the very first time you run this, then set the desired value
<pre>
	 runCount = 1
</pre>
- If you do not have WiFi set up yet then set:
<pre>
	 use_old_WiFi_setup = false
</pre>
- Finally run the program with
<pre>
	dofile ("main.lc")
</pre>

If it looks good you can now upload `init.lua` which will automatically run the program when the esp starts. Adjust it to use `.lc` or `.lua` as required.

You can create `init.lua` directly on the esp with this small snippet:
<pre>
	file.open("init.lua")
	file.writeline([[dofile("main.lc")]])
	file.close()
</pre>
or you can rename `main.lua` to `init.lua`.

To make the program sleep and restart regularly, set in `config.lua`
<pre>
	sleep_time = 60*1000000		-- 60 seconds
</pre>

If the program now runs unattended you may want to disable the logging (which slows it down and so uses more power) by setting in `config.lua`
<pre>
	print_log = false
</pre>

