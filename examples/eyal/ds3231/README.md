ds3231.lua
----------
This is a module for access to the DS3231 i2c RTC. It is mostly based on the module in the nodemcu-firmware github repository with many changes:

- Updated to work with the FP enabled FW.
- The century bit is used, with an assumed base year of 2000. The full year is accepted and returned.
- While the AM/PM mode is honoured it is cleared by `setTime()`.
- `getTemp()` was added to read the temperature. It is not a great feature as it has a +-3dC accuracy with a 0.25dC resolution. It is updated automatically every 64 seconds. `getTempNow()` forces a new conversion before reading it.
- The example displays the date & time in a fixed format. It can also be used to set the RTC.

How to set the time
-------------------

Edit `ds3231e.lua` and uncomment the `setTime()` line. Set the date and time on this line to the near future then upload it. The order of the fields is the same as on the following `getTime()` line.

On the esp8266, at the command line, run `node.compile("ds3231.lua")`. Now you are ready to set the date and time.

Wait for the time you selected to arrive and run `dofile("ds3231e.lua")`.

It is best now to comment the line and upload it again. Otherwise, if you run the example again, you risk resetting the RTC to a past time again.
