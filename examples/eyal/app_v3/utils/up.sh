#!/bin/sh

echod() {
        echo "`date '+%F %T'` $me: $@"
}

die() {
        echod "$@"
        exit 1
}

me="`basename $0 .sh`"
dir="`dirname "$0"`"

unset opts

while test 'x-' = "x${1:0:1}" ; do
	opts="$opts $1"
	shift
done

src="$1"
test -n "$src" || \
	die "missing file name"

tgt="$2"
test -n "$tgt" || \
	tgt="`basename "$src"`"

python "$dir/luatool.py" -p /dev/ttyUSB0 -f "$src" -t "$tgt" $opts

