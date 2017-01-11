#!/bin/bash

echod() {
	echo "`date '+%F %T'` $me: $@"
}

die() {
	echod "$@"
	exit 1
}

compile() {
	p="$1"
	$verbose && \
		echo "compiling '$p'"
	luac.cross $ccflags -o "$p".{lc,lua} || {
		echod "compile of '$p' failed $?"
		rc='true'
	}
}

me="`basename $0 .sh`"

ccflags=''
verbose='false'
while test -n "$1" ; do
	case "$1" in
	-s)
		ccflags='-s'
		;;
	-v)
		verbose='true'
		;;
	-*)
		die "bad option '$1'"
		;;
	*)
		die "unknown argument '$1'"
		;;
	esac
	shift
done

rc='false'
for f in *.lua ; do
	test -f "$f" || {
		echo "no '$f'"
		continue
	}
#	pgm="`basename "$f" .lua"	# remove '.lua' suffix
	pgm="${f:0:0-4}"		# remove '.lua' suffix
	case "$pgm" in
	i|i?|init|compile)
		continue
		;;
	main)
		ver="ver_$f"
		sed "s|#VERSION#|`date '+%F %T'` `hostname -s`:`pwd`|" "$f" >"$ver"
# DOS format:	sed "s|#VERSION#|`date '+%Y%m%d%H%M%S'` `hostname -s`:`pwd`|" "$f" >"$ver"
		config='/eyal/ej.netrc'
		test -f "$config" || \
			die "missing config file '$config'"
		read url ssid pass <"$config"
		sed -i "s/#SSID#/$ssid/;s/#PASS#/$pass/" "$ver"
		compile "ver_$pgm"
		rm "$ver"
		mv {ver_,}"$pgm.lc"
		continue
		;;
	esac
	compile "$pgm"
done

$rc && die "some compiles failed"
exit 0
