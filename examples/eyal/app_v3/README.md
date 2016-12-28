An example of reading temperature from a ds18b20 and submitting to a server
------------

It can also read the `bme280` and more.

This application reports more than just the temperature as it is used as a test program. It can also print a progress log. It has a few options that are only there for testing.

I will repeat: it does much work that is not required in the deployed version.

This version keeps track of the run number (as it sleeps for 60 seconds between runs) by reading the old published data back from the server.

To set a new access point run in this way:
<pre>
	use_old_WiFi_setup = false ; dofile ("init.lua")
</pre>

First edit `main.lua` to reflect your setup. Instructions inside.

Next you need to set the per-esp parameters in a file called `esp-[MAC].lua`.
Run the test program `show.lua` to display the MAC (in the required format) and the one-wire IDs of the sensors. The program can read multiple sensors. It also lists other details of the esp.

One example file `esp-18-FE-34-FE-85-3D.lua` is provided.
If the setup file is missing then `esp-test.lua` is used.

Note: Do not reset the esp after the uploads, but go through the following steps before starting with a `dofile()`.

After flashing the firmware (if necessary), start the esp and upload all the *.lua files.

The `main.lua` file contains a template `#VERSION#` that `lcall.sh` replaces with real data during compilation.


The server is a short python script `iot-server.py` which is launched by `iot-server.sh`.
I run two servers, one production `iot-server1.sh` and the other for testing `iot-server2.sh`.
It should be simple to adapt these scripts to windows...

Notes:
- This runs with nodemcu-firmware dev branch, using SDK 1.5.4.1.
- I did not test the ds3231 for a long while, so beware.
- I know that this note is terse but this is work in progress as I deal with all the issues I encounter.
- The app is broken into parts to make it fit in memory, and allow the files to be compiled. If running on a small memory module (e.g. esp-01 or esp-07) then the compile may fail is you have `init.lua`, so remove it an upload it later.
- The latest firmware with constants taken out of RAM makes things much better and only slightly slower.
- I find that the 512KB modules run much faster than the 4MB ones (esp-12, -12e, -201, nodeCU)
	Remove all unused modules in `app/include/user_modules.h`
	Set FLASH_512K in `app/include/user_config.h` to get fastest times.

You can stop any program by grounding pin gpio5 (D1) or any other pin that you set there.

### The following programs are executed in the listed order.

### init.lua
Note that there is no `init.lua`. Rename one of the `i[01].lua` as required.
`i0.lua` is a basic init script that runs the app.
`i1.lua` overrides a setting (used for testing).

### funcs.lua
Define some global functions, called first.

### main.lua
Establish the environment and set default values where necessary.

### esp-AA-BB-CC-DD-EE-FF.lua
Set configuration for a specific esp. It is named after the MAC address. If it is not found then `test.lua` is used.

### read.lua
Read devices.

### ds18b20.lua
A module to manage this one-wire temperature sensor.

### ds3231.lua
A module to read temperature from this I2C clock. It is a cut down version of the full device support module.

## i2clib.lua
Some common I2C functions, used by the `ds3231` module (and other devices not used in this project).

### wifi.lua
Establish a WiFi connection. This usually happens automatically.

### first.lua
On first run (when `rtcmem` is found uninitialised) request the last run number from the server.

### save.lua
The final act is to save the collected information. It is sent to the server using UPD, but TCP is also possible (though not tested recently). It can be changed to anything else desired (e.g. use MQTT).

### some test programs
`ie.lua` measure the time to establish a WiFi connection. Rename to `init.lua`.

`it.lua` cycle through 20s of deep sleep to measure sleep power usage. Rename to `init.lua`.

`show.lua` display information about the esp and possibly the one-wire devices attached.

