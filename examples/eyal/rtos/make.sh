#!/bin/bash

echod() {
	echo "`date '+%F %T'` $me: $@" | tee -a "$log"
}

die() {
	echod "$@"
	exit 1
}

me="`basename "$0" .sh`"
dir="`dirname "$0"`"
dir="`realpath "$dir"`"
log="$dir/build.log"
rm -f "$log"
echod "start with  $@"

clean='false'
while test -n "$1" ; do
	case "$1" in
	'-c')
		clean='true'
		;;
	*)
		die "unknown argument '$1'"
		;;
	esac
	shift
done

SDK_PATH="/data/esp8266/ESP8266_RTOS_SDK-master"
test -d "$SDK_PATH" || \
	die "no sdk path '$SDK_PATH'"
export SDK_PATH

BIN_PATH="$SDK_PATH/bin"
test -d "$BIN_PATH" || \
	die "no bin path '$BIN_PATH'"
export BIN_PATH

xtensa="/data/esp8266/xtensa-lx106-elf/bin"
test -d "$xtensa" || \
	die "no path '$xtensa'"
PATH="$xtensa:$PATH"

read f1 f2 ver fx <<<`grep '#define BUILD_DATE' 'include/user_config.h'`
ver="${ver//[^-_a-zA-Z0-9]/}"

echod "building '$ver'"

$clean && make clean

make BOOT=none APP=0 SPI_MODE=QIO SPI_SIZE_MAP=0 &>>"$log" || {
	echod "log is '$log'"
	die "##### make failed #####"
}

test -f "$BIN_PATH/esptool.py" || \
	cp -a /data/esp8266/nodemcu-firmware-master/tools/esptool.py "$BIN_PATH"

fw="$BIN_PATH/$ver.bin"

# Note: we shifted irom0text offset down as suggested here
#	http://kacangbawang.com/esp8266-512k-flash-compiling-using-rtos-sdk-1-3/
# ld/eagle.app.v6.ld changed from
#	irom0_0_seg :                         org = 0x40240000, len = 0x3C000
# to
#	irom0_0_seg :                         org = 0x40230000, len = 0x4C000
#
#irom='0x40000'	# original
 irom='0x30000'	# adjusted
srec_cat -output "$fw"                        -binary \
	"$BIN_PATH/eagle.flash.bin"           -binary -fill 0xff 0x00000 $irom \
	"$BIN_PATH/eagle.irom0text.bin"       -binary -offset $irom \
	"$BIN_PATH/esp_init_data_default.bin" -binary -offset 0x7c000 \
	"$BIN_PATH/blank.bin"                 -binary -offset 0x7e000
