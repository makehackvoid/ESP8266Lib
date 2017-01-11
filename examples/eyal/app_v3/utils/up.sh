#!/bin/sh

# 21 Aug 16 EL Remove empty lines

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

 opts='--baud 115200'
#opts='--baud 9600'
test -n "$BAUD" && \
	opts="--baud $BAUD"

tmp="$src.tmp"
echod "tmp='$tmp'"
# remove empty lines
sed '/^\r/d;/^--[ \t]/d' "$src" >"$tmp"

python "$dir/luatool.py" -p /dev/ttyUSB0 $opts -f "$tmp" -t "$tgt" $opts
rm -f "$tmp"
