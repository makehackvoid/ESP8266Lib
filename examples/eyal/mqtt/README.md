ds18b20/
--------

In this example the temperature is read from a ds18b20. To count the run number across a dsleep restart we retriev it (subscribe) from the older submission first.

ds3231/
-------
In this example the temperature is read from a ds3231. This is not as accurate as the ds18b20 but we can get the time as well as save the run number in the provided nvram (we use the 24 bit alarm2 area).

