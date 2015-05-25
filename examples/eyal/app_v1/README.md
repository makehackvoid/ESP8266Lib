An example of reading temperature from a ds18b20 and submitting to a server
------------

The app reports more than just the temperature as it is used as a test program. It can also print a progress log. It has a few options that are only there for testing.

This version keeps track of the run number (as it sleeps for 60 seconds between runs) by reading the old published data back from the server. You can, when running it for the first time after flash+load, start it with
<pre>
	RunCount = 1; use_old_WiFi_setup = false; dofile ("i.lua")
</pre>
and this will start with a run number of 1. Otherwise it will continue from the old run number.

I have a new trivial module built `app/modules/misc.c` which provides access to the esp RTC for keeping track of stats. You probably do not have it, in which case `first.lua` will fetch the last run number from the server. You will also not be able to track failures counts.

First edit `main.lua` to reflect your setup. Instructions inside the program.
Or you can set only a few things as the top of `init.lua` as you can see there in the `if false` block.

- After flashing the firmware (if necessary), start the esp and upload these programs:
<pre>
	[Note: You may want to first do a file.format() to ensure a clean file system]
	init.lua as i.lua
	main.lua
	funcs.lua
	read-ds18b20.lua
	ds18b20.lua
	WiFi.lua
	first.lua
	send-tcp.lua
	send-udp.lua
</pre>
I do not upload `init.lua` with the real name to avoid getting an unstoppable loop. However, the program should stop if you short `GPIO5` (the magic pin as configured in `main.lua`).
If you can compile programs you want to upload this too:
<pre>
	compile.lua
</pre>
It has been a while since I tested the ds3231 but you can try. Instead of the ds18b20 modules upload
<pre>
	ds3231.lua
	i2clib.lua
	read-ds3231.lua
</pre>
I do not upload modules manually but use a script `uploadall.bat` which also modifies `main.lua` to show the date, time and directory of the app (using the `upmain.bat` script).

- If you can compile programs then run
<pre>
	node.compile("compile.lua")
	dofile ("compile.lc")
</pre>
At this point it is best to `node.restart()` to get a clean slate.
- If you want to start counting runs from '1' (rather than continuing from the last run) or this is the very first time you run this, then set
<pre>
	 runCount = 1
</pre>
- If you do not have WiFi set up yet then set:
<pre>
	 use_old_WiFi_setup = false
</pre>
It should be said that the runCount is of no real value other than my tracking of the tests, so you can just ignore it.

- now start the server. I run it on linux but it is strivial to run on windows too. `server.sh` looks at all the avilable log files and extract the latest recorded message for each, then starts the actual server `server.py`.

You can start the server directly with `python server.py '/path/to/your/logs'`.

The server can provide some stats on all the active modules if you access it from your browser at `http://e7:11883/stats` (replace `e7` with your server hostname).

- Finally start the program with
<pre>
	dofile ("i.lua")
</pre>
If it did what you want (check the server to see that you have a good reading) then you can rename
<pre>
	file.rename("i.lua", "init.lua")
</pre>
Turn the module off (remove power), install it where you want it to stay, and power it up.
If it does not report within a minute I recommend toggling the reset pin and checking if it works then. Otherwise you have an investigation on your hand...

