ds3231.lua
----------
This is a module to access the DS3231 i2c RTC. It is mostly based on the module in the nodemcu-firmware github repository with some changes:

- Updated to work with the FP enabled FW.
- The century bit is used, with an assumed base year of 2000. The full year is accepted and returned.
- `getTemp()` was added to read the temperature. It is not a great feature as it has a +-3dC accuracy with a 0.25dC resolution. It is updated automatically every 64 seconds.
- The example displays the date & time is a fixed format. It cxan also be used to set the RTC.

How to set the time
-------------------

Edit the example and uncomment the setTime() line. Set the date and time on this line to the near future then upload it.
On the esp8266, at the command line, run `dofile("ds3231e.lua")` when the time you selected arrives.

It is best now to comment the line and upload it again. Otherwise, if you run the example again, you risk resetting the RTC to a past time.
