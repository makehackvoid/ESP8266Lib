#!/bin/bash

echod() {
	echo "`date '+%F %T'` $me: $@" | tee -a "$log"
}

die() {
	echod "$@"
	echod "log is '$log'"
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

read f1 f2 ver fx <<<`grep '#define BUILD_DATE' 'include/user_config.h'`
ver="${ver//[^-_a-zA-Z0-9]/}"

echod "building '$ver'"

SDK_PATH='/opt/Espressif/esp_iot_sdk_v1.5.1'
test -d "$SDK_PATH" || \
	die "no sdk path '$SDK_PATH'"
export SDK_PATH

BIN_PATH="$SDK_PATH/bin"
test -d "$BIN_PATH" || \
	die "no bin path '$BIN_PATH'"
export BIN_PATH

xtensa="/opt/xtensa-lx106-elf/bin"
test -d "$xtensa" || \
	die "no path '$xtensa'"
PATH="$xtensa:$PATH"

$clean && make clean &>>"$log" || \
	die "##### make failed #####"

make COMPILE=gcc BOOT=none APP=0 SPI_MODE=QIO SPI_SIZE_MAP=0 &>>"$log" || \
	die "##### make failed #####"

fw="$BIN_PATH/$ver.bin"

irom='0x40000'		# original offset
srec_cat -output "$fw"                        -binary \
	"$BIN_PATH/eagle.flash.bin"           -binary -fill 0xff 0x00000 $irom \
	"$BIN_PATH/eagle.irom0text.bin"       -binary -offset $irom \
	"$BIN_PATH/esp_init_data_default.bin" -binary -offset 0x7c000 \
	"$BIN_PATH/blank.bin"                 -binary -offset 0x7e000

