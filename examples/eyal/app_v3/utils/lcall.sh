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
#	echo "compiling '$p'"
	luac.cross $ccflags -o "$p".{lc,lua} || {
		echod "compile of '$p' failed $?"
		rc='true'
	}
}

me="`basename $0 .sh`"

 ccflags='-s'
#ccflags=''

rc='false'
for f in *.lua ; do
	test -f "$f" || {
		echo "no '$f'"
		continue
	}
#	pgm="`basename "$f" .lua"	# remove '.lua' suffix
	pgm="${f:0:0-4}"		# remove '.lua' suffix
	case "$pgm" in
	i|init|compile)
		continue
		;;
	main)
		sed "s|#VERSION#|`date '+%F %T'` `hostname -s`:`pwd`|" "$f" >"ver_$f"
# DOS format:	sed "s|#VERSION#|`date '+%Y%m%d%H%M%S'` `hostname -s`:`pwd`|" "$f" >"ver_$f"
		compile "ver_$pgm"
		rm "ver_$f"
		mv {ver_,}"$pgm.lc"
		continue
		;;
	esac
	compile "$pgm"
done

$rc && die "some compiles failed"
exit 0
