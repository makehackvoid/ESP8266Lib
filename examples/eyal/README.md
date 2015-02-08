wifi-3.lua

  An example of code that I use to test my app. It publishes an item periodically (no dsleep).
  It can either just publish a count or actually read the temperature off a ds18b20. This last usage always
  fails me with "not enough memory" when loading the required module if using firmware 20150227.
  When using fw 20150216 it fails to connect to the mqtt broker.

wifi-4.lua (uploaded as "t")

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
B1¦"¦:&¦;¦;!G¦R¦B¦¦d+¦¦¦??¦kD¦||¦?¦,?$j
                                       t¦kD¦$¦¦¦¦¦

NodeMCU 0.9.5 build 20150126  powered by Lua 5.1.4
lua: cannot open init.lua
>
</pre>
  BTW, after a fw flash (there is no station info) it fails to make the connection at all
and fails early with:

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

  With fw 20150227 it manages to fail with a proper message:

NodeMCU 0.9.5 build 20150127  powered by Lua 5.1.4
lua: cannot open init.lua
> dofile("t")
main
ds18b20_init
used memory before=14884
error loading module 'ds18b20' from file 'ds18b20.lua':
        not enough memory
>

  One can see that this fw uses much more memory (over 2KB more).
  Anyone knows how much memory this processor has?

To be continued...
