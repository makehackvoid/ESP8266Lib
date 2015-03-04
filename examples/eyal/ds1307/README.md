ds1307.lua
----------
This is a module to access the DS1307 i2c RTC. It is vaguely based on the module in the nodemcu-firmware github repository.

How to set the time
-------------------

Edit the example and uncomment the setTime() line. Set the date and time on this line to the near future then upload it.
On the esp8266, at the command line, run `dofile("ds1307e.lua")` when the time you selected arrives.

It is best now to comment the line and upload it again. Otherwise, if you run the example again, you risk resetting the RTC to a past time.
