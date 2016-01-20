This is my attempt at using the RTOS SDK. It is uploaded 'as is'.
======

Edit `make.sh` with your paths.

Edit `user/user_main.c` with your setup (`SSID/PASS/SERVER`).

Edit `lib/folder1/env.c` to add  your esp. Only the first 5 fields are used now. 'client' is the esp.

Edit `include/user_config.h` and set `BUILD_DATE`

Run
```
	./make.sh
```
then check
```
	build.log
```
You now have `bin/BUILD_DATE.bin` to flash at `0x00000`.

On your server run
```
	ncat -l4u 31883
```
Then start your ESP.
