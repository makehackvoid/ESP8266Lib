#!/bin/sh

# 21 Aug 16 EL Remove empty lines from *.lua
# 20 Dec 16 EL Upload larger files first
#	EL Add 'files.txt'
# 14 Jan 17 EL Sort and trim 'files.txt'

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

here="`readlink -f '.'`"
there="`readlink -f '/www/upload'`"
upfile="$there/u.lua"
srclist="$there/files.txt"

test "$here" = "$there" && copy='false' || copy='true'

mac=''		# upload specific mac file
upit='true'	# upload to esp
text='true'	# upload 'files.txt'
while test -n "$1" ; do
	case "$1" in
	-n)
		upit='false'
		;;
	-x)
		text='false'
		;;
	-*)
		die "unkbown option '$1'"
		;;
	*)
		test -n "$mac" && \
			die "unkbown argument '$1'"
		mac="$1"
		;;
	esac
	shift
done

test -n "$mac" || mac='*'

{
	echo "-- file: $upfile"
	echo "-- created: `date '+%F %T'`"S

	cat "$dir/upload.lua"

	echo -n 'download ({'
	uplist=''
	lslist=''
	for file in i?.lua *.lc ; do
		test -f "$file" || continue
		tmp=''
		upthis='true'	# upload this file
		case "$file" in
		*.lua)
			$copy && {
				tmp="$file.tmp"
				sed '/^\r/d;/^--[ \t]/d' "$file" >"$tmp"
				touch -r "$file" "$tmp"
			}
			;;
		esp-test.*)
			;;
		esp-*.lc)
			upthis='false'	# only copy to $there
			;;
		init.*|compile.*|test.*)
			continue	# ignore
			;;
		ds3231.*|i2clib.*)
			continue	# ignore, needed if using i2c
			;;
		*)
			;;
		esac

		$copy && {
			lslist="$lslist ${file/.lc/.lua}"
			if test -n "$tmp" ; then
				mv "$tmp" "$there/$file"
			else
				cp -a "$file" "$there"
			fi
			chmod 666 "$there/$file"
		}

		$upthis && \
			uplist="$uplist $file"
	done
	col=0
	for file in `(cd "$there" ; ls -S $uplist)` ; do
		col=$((col+1))
		test $col -gt 5 && {
			col=1
			echo ""
		}
		echo -n "'$file',"
	done
#	echo -n "my_esp_config()"	# now done in upload.lua
	echo -n "esp"			# will upload correct "esp-MAC.lc"
	$text && \
		echo -n ",'`basename "$srclist"`'"
	echo '}, "/upload")'
} >"$upfile"

$text && {
	echod "source files used:" >"$srclist"
	ls -lt --time-style='+%F %T' $lslist | cut -d' ' -f 5- >>"$srclist"
}

compile "$upfile"

$upit && \
	"$dir/up.sh" --dofile "$dir/bootstrap.lua"
