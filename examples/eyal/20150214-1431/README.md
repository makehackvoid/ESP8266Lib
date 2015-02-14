Read the ds18b20 and publish to mqtt
------------------------------------

This example is broken into parts and each is run using dofile(). This reduces the memory usage.

These are the used files that need to be uploaded to the es8266.

<b>init.lua</b>
	Runs automatically after boot
getPass.lua
	Read the ssid/passphrase from a file 'pass'
getRunCount.lua
	Keep an incremental count of runs (in a file 'runCount'). Useful for testing
doWiFi.lua
	Connects to the wifi access point
readTemp.lua
	Read the temperature from the ds18b20
doMQTT.lua
	Connects to MQTT and publishes
ds18b20.lua
	The ds18b20 driver from nodemcu-firmware github


compile.lua
	Run this to compile the above modules
makePass.lua
	Run this (after entering your details) to create the necessary 'pass' file

