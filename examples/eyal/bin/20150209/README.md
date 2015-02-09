<b>[ 9 Feb 15 EL] Building the SDK first, then the firmware.</b>

Build the SDK
<pre>
cd
git clone https://github.com/pfalcon/esp-open-sdk.git
# done at 19:40
cd esp-open-sdk
make STANDALONE=y
# takes about 2.5 hours
</pre>

Build the firmware
<pre>
cd
git clone https://github.com/nodemcu/nodemcu-firmware.git
# done at 19:22
cd nodemcu-firmware
export PATH=/home/esp8266/esp-open-sdk/xtensa-lx106-elf/bin:$PATH
vi app/include/user_config.h
# change BUILD_DATE to your liking, I used: "build 20150209-eyal"
make
# takes a few minutes
</pre>

The result is here
<pre>
ls -l bin
#total 380
# -rw-rw-r-- 1 esp8266 esp8266  45920 Feb  9 23:11 0x00000.bin
# -rw-rw-r-- 1 esp8266 esp8266 330892 Feb  9 23:11 0x10000.bin
# -rw-rw-r-- 1 esp8266 esp8266   4096 Feb  9 19:22 blank.bin
# -rw-rw-r-- 1 esp8266 esp8266    128 Feb  9 19:22 esp_init_data_default.bin
</pre>

Flash as usual (this is on my windows laptop)
<pre>
c:\Python2\Python.exe esptool.py --port COM7 write_flash 0x00000 0x00000.bin 0x10000 0x10000.bin
</pre>

Note required space
<pre>
cd
du -sh esp-open-sdk/ nodemcu-firmware/
# 3.0G    esp-open-sdk/
# 34M     nodemcu-firmware/
</pre>

