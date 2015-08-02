An example of reading temperature from a ds18b20 and submitting to a server
------------

This application reports more than just the temperature as it is used as a test program. It can also print a progress log. It has a few options that are only there for testing.

I will repeat: it does much work that is not required in the deployed version.

This version keeps track of the run number (as it sleeps for 60 seconds between runs) by reading the old published data back from the server.
<pre>
	runCount = true; use_old_WiFi_setup = false; dofile ("init.lua")
</pre>

First edit `main.lua` to reflect your setup. Instructions inside.

Next you need to set the per-esp parameters in a file called `esp-[MAC].lua`.
Run the test program `show-ow.lua` to display the MAC (in the required format) and the one-wire IDs of the sensors. The program can read multiple sensors.

One example file `esp-18-FE-34-FE-85-3D.lua` is provided.
If the setup file is missing then `esp-test.lua` is used.

Note: Do not reset the esp after the uploads, but go through the following steps before starting with a `dofile()`.

After flashing the firmware (if necessary), start the esp and upload all the *.lua files.

The `main.lua` file contains a template `#VERSION#` that `upver.bat` can replace with real data.

I recommend that you compile the programs with
<pre>
	dofile("compile.lua")
</pre>

I have an extra module in the firmware that provides access to RTC memory where some stats are collected and the run number is counted. None of these are critical for the basic operation of the program.
Newer firmware has (or will soon have) RTC memory API as standard.

The server is a short python script `iot-server.py` which is launched by `iot-server.sh`.
I run two servers, one production `iot-server2.sh` and the other for testing `iot-server2.sh`.
It should be simple to adapt these scripts to windows...

Notes:
- I did not test the ds3231 for a long while, so beware.
- I know that this note is terse but this is work in progress as I deal with all the issues I encounter.
- The app is broken into parts to make it fit in memory, and allow the files to be compiled. If running on a small memory module (e.g. esp-01 or esp-07) then the compile may fail is you have `init.lua`, so remove it an upload it later.
- The latest firmware with constants taken out of RAM makes things much better and only slightly slower.
- I find that the 512KB modules run much faster than the 4MB ones (esp-12, -12e, -201, nodeCU)
