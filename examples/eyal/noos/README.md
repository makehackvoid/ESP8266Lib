A re-implementation of my app using the no-os SDK
===

*** This is work in progress ***

Place this directory inside the top SDK directory. In my case it is `esp_iot_sdk_v1.5.1`
This project fits in a small 512KB module.

You can follow the standard instructions as `readme.txt` says.

Or run my `make.sh` after adjusting it to your environment:

	1 include/user_config.h: set BUILD_DATE

	2 make.sh: Set `SDK_PATH`

	3 make.sh: set `xtensa` path

	4 run `./make.sh -c`

Flash an run.
To see the packets it send I usually run
	ncat -l4u 31883
on the server selected in user/user_main.c

	static const uint8      SERVER[4] = {192,168,3,4};	// set your server here

