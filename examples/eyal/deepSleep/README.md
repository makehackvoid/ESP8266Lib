An example of reading temperature from a ds18b20 and submitting to a server, using Arduino IDE on an esp8266
------------

This application reports more than just the temperature as it is used as a test program. It can also print a progress log. It has a few options that are only there for testing.

It is actually a minimal program and needs some extra work before it is identical to the NodeMCU/lua version. The purpose here is to compare the environments. It is now reasonably close to that one.

There are some constants to set in `user_config.h`. You will need the ESP8266WiFi library.

It is worth mentioning that for one-wire to work you need a pullup resistor on the data pin.
