at24c32.lua
----------
This is a module for access to the AT24C32 i2c EEPROM. It Should probably work with other members of this family.

An unusual concern is the fact that following a write there must be a delay (tWR) before the next operation. There is no "busy" flag to check so this program simply retries but fails if the failures continue for longer that tWR (10ms in the datasheet I have).

My tests show that the actual required wair is much shorter. Writing 2048 individual bytes caused a total of 46 retries which added up to 26049us (26ms). Either this eeprom is much faster that claimed of the esp8266 lua i2c is very slow...

