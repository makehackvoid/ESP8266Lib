#!/bin/sh

echod() {
	echo "`date '+%F %T'` $me: $@"
}

die() {
	echod "$@"
	exit 1
}

compile () {
	f="$1"
	luac.cross -s -o "${f/.lua/.lc}" "$f"
}

me="`basename $0 .sh`"
dir="`dirname "$0"`"

tmpname="$me-$$.lua"
tmp="$HOME/tmp/$tmpname"

here="`readlink -f '.'`"
there="`readlink -f '/www/upload'`"
upfile="$there/u.lua"

test "$here" = "$there" && copy='false' || copy='true'

upit='true'
test 'x-n' = "x$1" && {
	upit='false'
	shift
}
mac="$1" ; shift
test -n "$mac" || mac='*'

{
	echo "-- file: $upfile"
	echo "-- created: `date '+%F %T'`"S

	cat "$dir/upload.lua"

	echo -n 'download ({'
	n=0
	col=0
	for file in i.lua *.lc ; do
		test -f "$file" || continue
		case "$file" in
		esp-test.*)
			upthis='true'	# copy+upload
			;;
		esp-*.*)
			upthis='false'	# copy only
			;;
		init.*|compile.*|test.*)
			continue	# ignore
			;;
		ds3231.*|i2clib.*)
			continue	# ignore, needed if using i2c
			;;
		*)
			upthis='true'	# copy+upload
			;;
		esac

		$upthis && {
			col=$((col+1))
			test $col -gt 5 && {
				col=1
				echo ""
			}
			n=$((n+1))
			echo -n "'$file',"
		}

		$copy && \
			cp -a "$file" "$there"
	done
	echo -n "my_esp_config(),"	# will upload correct "esp-MAC.lc"
	echo '}, "/upload")'
} >"$upfile"
compile "$upfile"

$upit && \
	"$dir/up.sh" --dofile "$dir/bootstrap.lua"

