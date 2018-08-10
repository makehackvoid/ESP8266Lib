PC programs used with the lua project
===

bootstrap.lua
==

A script to run on the esp to fetch all the compiled lua files from the (web) server. It is a very short program that fetches `u.lc` (see below) and runs it.
This is much quicker than the usual upload of the lua source and compile on the esp.

iot-server.py
==

The python iot server.

iot-server.sh
==

The launcher of the python iot server.

iot-server1.sh, iot-server2.sh, iot-servers.sh
==

Launchers for two servers (on different ports). One is the production server the other used for testing.
They both are launched when the server host boots.

lcall.sh
==

Compile all the lua modules. You need to have `luac.cross` installed.

pup.sh
==

Prepare a lua program (`u.lua`, using `upload.lua`) to fetch all the other necessary modules.

up.sh
==

A simple wrapper for `luatool.py` that I use.

upload.lua
==

Wirelessly fetch a file from a web server (using http). It gets embedded into a larger script (`u.lc`) by pup.sh which is then uploaded and run on the esp.

send.lua
==

Wirelessly download a file from the esp

