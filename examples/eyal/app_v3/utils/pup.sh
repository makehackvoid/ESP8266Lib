#!/bin/sh

# 21 Aug 16 EL Remove empty lines from *.lua
# 20 Dec 16 EL Upload larger files first
#	EL Add 'files.txt'

echod() {
	echo "`date '+%F %T'` $me: $@"
}

die() {
	echod "$@"
	exit 1
}

compile () {
	f="$1"
	luac.cross $ccflags -o "${f/.lua/.lc}" "$f" || \
		die "compiling '$f.lua' failed"
}

me="`basename $0 .sh`"
dir="`dirname "$0"`"

#ccflags='-s'	# strip
 ccflags=''

tmpname="$me-$$.lua"
tmp="$HOME/tmp/$tmpname"

here="`readlink -f '.'`"
there="`readlink -f '/www/upload'`"
upfile="$there/u.lua"
srclist="$there/files.txt"

echod "source files used:" >"$srclist"

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
	tmp=''
	uplist=''
	for file in i?.lua *.lc ; do
		test -f "$file" || continue
		tmp=''
		case "$file" in
		*.lua)
			ls -l "$file" >>"$srclist"
			$copy && {
				tmp="$file.tmp"
				sed '/^\r/d;/^--[ \t]/d' "$file" >"$tmp"
			}
			;;
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

		$copy && {
			ls -l "${file/.lc/.lua}" >>"$srclist"
			if test -n "$tmp" ; then
				mv "$tmp" "$there/$file"
			else
				cp -a "$file" "$there"
			fi
			chmod 666 "$there/$file"
		}

		$upthis && {
			uplist="$uplist $file"
		}
	done
#	uplist="$uplist files.txt"
	col=0
	for file in `(cd "$there" ; ls -S $uplist)` ; do
		col=$((col+1))
		test $col -gt 5 && {
			col=1
			echo ""
		}
		echo -n "'$file',"
	done
#	echo -n "my_esp_config()"	# will upload correct "esp-MAC.lc"
	echo -n "esp"			# will upload correct "esp-MAC.lc"
	echo '}, "/upload")'
} >"$upfile"
compile "$upfile"

$upit && \
	"$dir/up.sh" --dofile "$dir/bootstrap.lua"
