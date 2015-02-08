<b>wifi-3.lua</b>

  An example of code that I use to test my app. It publishes an item periodically (no dsleep).
  It can either just publish a count or actually read the temperature off a ds18b20. This last usage always
  fails me with "not enough memory" when loading the required module if using firmware 20150227.
  When using fw 20150216 it fails to connect to the mqtt broker.

<b>wifi-4.lua (uploaded as "t")</b>

 This is similar to the -3 but I kept the console logs.

  With fw 20150226 (no fp) the sensor module loads but the program soon fails:
<pre>
NodeMCU 0.9.5 build 20150126  powered by Lua 5.1.4
lua: cannot open init.lua
> dofile("t")
main
ds18b20_init
used memory before=12288
used memory after =17408
Found 1 ds18b20 devices
exit ds18b20_init
main_1
main_2
publishData
mqtt.Client
B1Â¦"Â¦:&Â¦;Â¦;!GÂ¦RÂ¦BÂ¦Â¦d+Â¦Â¦Â¦??Â¦kDÂ¦||Â¦?Â¦,?$j
                                       tÂ¦kDÂ¦$Â¦Â¦Â¦Â¦Â¦

NodeMCU 0.9.5 build 20150126  powered by Lua 5.1.4
lua: cannot open init.lua
>
</pre>
  BTW, after a fw flash (there is no station info) it fails to make the connection at all
and fails early with:
<pre>
NodeMCU 0.9.5 build 20150126  powered by Lua 5.1.4
lua: cannot open init.lua
> dofile("t")
main
ds18b20_init
used memory before=12288
used memory after =17408
Found 1 ds18b20 devices
exit ds18b20_init
main_1
not enough memory
>
</pre>
  With fw 20150227 it manages to fail with a proper message:
<pre>
NodeMCU 0.9.5 build 20150127  powered by Lua 5.1.4
lua: cannot open init.lua
> dofile("t")
main
ds18b20_init
used memory before=14884
error loading module 'ds18b20' from file 'ds18b20.lua':
        not enough memory
>
</pre>
  One can see that this fw uses much more memory (over 2KB more).
  Anyone knows how much memory this processor has?

Finally, runinng with <pre>fake_it = true</pre> has no issues:
<pre>
node.restart()
> J¦C¦¦3j¦¦¦1¦1 ¦¦¦e¦¦¦

NodeMCU 0.9.5 build 20150126  powered by Lua 5.1.4
lua: cannot open init.lua
> dofile("t")
main
ds18b20_init
exit ds18b20_init
main_1
main_2
publishData
mqtt.Client
m:connect
exit publishData
exit main_2
exit main_1
exit main
> connected
exit connected
publish
readTemperature
exit readTemperature (1)
exit publish
publish
readTemperature
exit readTemperature (2)
exit publish
publish
readTemperature
exit readTemperature (3)
exit publish
publish
readTemperature
exit readTemperature (4)
exit publish
publish
readTemperature
exit readTemperature (5)
exit publish
</pre>
And the broker shows:
<pre>
$ mosquitto_sub -i e4 -h 192.168.2.7 -v -t 'eyal/esp-07'
eyal/esp-07 1dC 12288
eyal/esp-07 2dC 12288
eyal/esp-07 3dC 12288
eyal/esp-07 4dC 12288
eyal/esp-07 5dC 12288
</pre>
Memory usage did not change up to 90 iterations, however after 90 times I do not see any new published values.

To be continued...
