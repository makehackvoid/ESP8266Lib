Publish ds18b20 reading
-----------------------
This is a test program.
This program reads the ds18b20 and publishes it, then sleeps for 2 seconds.

After some memory shortage issues (when loading ds18b20.lua) the program was broken into pieces.

Also, it mostly runs outside the init.lua context, again to avoid said memory issues.

Beyond reading the temperature (using a module from the nodemcu github) and publishing it to mqtt,
there are a few other features to note:

- The ssid/passphrase are read from a file (see getPass.lua), so these are not in the code.
  A short program (make-pass.lua) can be modified and run to create this file.

- To allow stopping the program (which is in a loop) we check a GPIO pin and abort if requested.
  This is done in init.lua.

- Counting the runs is done in getRunCount.lua, which keeps the count in a file runCount.

I usually start a run (after uploading the modules) with
   file.remove ("runCount"); node.restart()

The wakeup from dsleep did not work until recently. I use a firmware I built this morning (13/Feb) from the repository, which is available in another directory nearby.

Note: this is still work in progress.

