[ 9 Feb 15 EL] grabbed 19:40 (esp-...), 19:22 (nodemcu-...)

<pre>
cd
git clone https://github.com/pfalcon/esp-open-sdk.git
cd esp-open-sdk
make STANDALONE=y
# takes about 2.5 hours

cd
git clone https://github.com/nodemcu/nodemcu-firmware.git
cd nodemcu-firmware
export PATH=/home/esp8266/esp-open-sdk/xtensa-lx106-elf/bin:$PATH
vi app/include/user_config.h
# change BUILD_DATE to your liking, I used: "build 20150209-eyal"
make
# takes a few minutes

cd
du -sh esp-open-sdk/ nodemcu-firmware/
# 3.0G    esp-open-sdk/
# 34M     nodemcu-firmware/

ls -l bin
#total 380
# -rw-rw-r-- 1 esp8266 esp8266  45920 Feb  9 23:11 0x00000.bin
# -rw-rw-r-- 1 esp8266 esp8266 330892 Feb  9 23:11 0x10000.bin
# -rw-rw-r-- 1 esp8266 esp8266   4096 Feb  9 19:22 blank.bin
# -rw-rw-r-- 1 esp8266 esp8266    128 Feb  9 19:22 esp_init_data_default.bin

%py% esptool.py --port COM7 write_flash 0x00000 0x00000.bin 0x10000 0x10000.bin
</pre>
