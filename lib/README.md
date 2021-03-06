Lib Directory
-------------

This directory holds LUA library files needed
for the module.

simpleconfig.lua
----------------

This module allows you store settings in a convention .ini
style file rather than hardcoding values into your programs.

It uses settings.ini which is the default. You can create the
file on your pc and then transfer it to the ESP8266 module with
a file-copy utility.

settings.ini
<pre>
host=192.168.0.50
</pre>

To use this subroutine, first use load_config() to load all
the values from the configuration into memory.

<pre>
> =load_config()
</pre>

Once you have done this, you can access all the values in
the configuration using the dictionary:

<pre>
> =config['host']
192.168.0.50
</pre>
