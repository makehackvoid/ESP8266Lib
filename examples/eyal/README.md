A collection of programs and modules for use on the esp8266 (mostly) with lua firmware (mostly)
======

esp32/
-----

Stuff done on the new esp-32.

misc/
-----

A place for me to put stuff.

noos/
-----

A no-os SDK implementation of the same app.

rtos/
-----

An RTOS SDK implementation of the same app. Had issues so it was abandoned :-(

deepSleep/
---------

A similar application written as an arduino sketch. I know that this is a bad name...

app_v3/
-------

An even later version of the application.

app_v2/
-------

A later version of the application.

app_v1/
-------

A lua app where a ds18b20 temperature sensor is read and the result is sent to a network server.
This is a test program, with more code than is necessary to accomplish this task.

bin/
----

Some firmwares that were built locally while waiting for the official ones.

mqtt/
-----

Examples of programs that read the temperature and publish the reading to MQTT.

ds3231/, ds1307/, lm75/, pca9555/, at24c32/
-------

Basic manupulation of some i2c modules.

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

clock/
------

Sketches for the MHV wall clock.

