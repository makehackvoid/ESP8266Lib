ds3231.lua
----------
This is a module to access the DS3231 i2c RTC. It is mostly based on the module in the nodemcu-firmware github repository with some changes:

- Updated to work with the FP enabled FW.
- The century bit is used, with an assumed base year of 2000. The full year is accepted and returned.
- `getTemp()` was added to read the temperature. It is not a great feature as it has a +-3dC accuracy with a 0.25dC resolution. It is updated automatically every 64 seconds.
- The example displays the date & time is a fixed format. It cxan also be used to set the RTC.
