Read the ds18b20 and publish to mqtt
------------------------------------

This example is broken into parts and each is run using dofile(). This reduces the memory usage.

These are the used files that need to be uploaded to the es8266.

<b>init.lua</b>
	Runs automatically after boot
	</b>
	Read the ssid/passphrase from a file 'pass'
	
<b>getRunCount.lua</b>
	Keep an incremental count of runs (in a file 'runCount'). Useful for 
	
<b>doWiFi.lua</b>
	Connects to the wifi access 
	
<b>readTemp.lua</b>
	Read the temperature from the ds18b20
	
<b>doMQTT.lua</b>
	Connects to MQTT and publishes
	
<b>ds18b20.lua</b>
	The ds18b20 driver from nodemcu-firmware github


<b>compile.lua</b>
	Run this to compile the above modules

<b>makePass.lua</b>
	Run this (after entering your details) to create the necessary 'pass' file

