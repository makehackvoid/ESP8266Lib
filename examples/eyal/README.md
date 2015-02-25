bin/
----

Some firmwares that were built locally while waiting for the official ones.

ds18b20/
--------

A example of a (I hope working) program that reads from a ds18b20 and publishes the reading to MQTT.

ds3231/
-------

Basics manupulation of the i2c RTC module.

reBoot.lua
----------

A test program that repeatedly reboots (3 seconds dsleep). Used to test the wakeup problem.

reCount.lua
-----------

A test program that repeatedly increments a counter in a file, then reboots (3 seconds dsleep). Used to test the wakeup problem.

reRead.lua
----------

A test program that repeatedly reads the ds18b20, then reboots (3 seconds dsleep). Used to test the wakeup problem.

reWiFi.lua
----------

A test program that waits for WiFi to acquire an IP, then reboots (3 seconds dsleep). Used to test the wakeup problem.
