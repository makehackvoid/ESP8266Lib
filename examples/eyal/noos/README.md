A re-implementation of my app using the no-os SDK
===

*** This is work in progress ***

Place this directory inside the top SDK directory. In my case it is `esp_iot_sdk_v1.5.1`.
BTW this project fits in a small 512KB module.

You can follow the standard instructions as `readme.txt` says.

Or run my `make.sh` after adjusting it to your environment:

	1 include/user_config.h: set `BUILD_DATE` as you wish

	2 make.sh: Set `SDK_PATH`

	3 make.sh: set `xtensa` path

	4 run `./make.sh -c`

Flash the file in the BIN_PATH/BUILD_DATE.

To see the packets it sends I usually run
```
	ncat -l4u 31883
```
on the server selected in user/user_main.c
```
static const uint8      SERVER[4] = {192,168,3,4};	// set your server here
```

Note: it seems to work, mostly, but the readings from the ds18b20 is a bit shakey. Note the temperature in the last column. It is reported every 2 seconds.

```
show esp-12f 763 times=L0.224,T244,s0.052,z160,r0.023,w0.118,S0.000,t0.141 adc=4.344 vdd=3.103 30.3750
show esp-12f 764 times=L0.225,T244,s0.052,z160,r0.023,w0.117,S0.000,t0.140 adc=4.368 vdd=3.107 31.2500
show esp-12f 765 times=L0.224,T245,s0.054,z160,r0.023,w0.118,S0.000,t0.142 adc=4.296 vdd=3.111 29.9375
show esp-12f 766 times=L0.227,T245,s0.052,z160,r0.023,w0.117,S0.000,t0.140 adc=4.356 vdd=3.107 30.5625
show esp-12f 767 times=L0.224,T245,s0.052,z160,r0.023,w0.117,S0.000,t0.140 adc=4.332 vdd=3.107 31.5625
show esp-12f 768 times=L0.224,T245,s0.052,z160,r0.023,w0.119,S0.000,t0.142 adc=4.356 vdd=3.107 30.4375
show esp-12f 769 times=L0.226,T246,s0.052,z160,r0.023,w0.117,S0.000,t0.140 adc=4.368 vdd=3.104 31.1250
show esp-12f 770 times=L0.224,T246,s0.054,z160,r0.023,w0.118,S0.000,t0.141 adc=4.296 vdd=3.107 31.0000
```
