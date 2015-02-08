Lib Directory
-------------

This directory holds LUA library files needed
for the module.

simpleconfig.lua
----------------

This module allows you store settings in a convention .ini
style file rather than hardcoding values.

To use this subroutine, first use load_config() to load all
the values from the configuration into memory.

> =load_config()

Once you have done this, you can access all the values in
the configuration using the dictionary:

> =config['host']
192.168.0.50

