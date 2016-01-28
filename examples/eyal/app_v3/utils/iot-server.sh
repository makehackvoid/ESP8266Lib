#!/bin/sh

echod() {
        echo "`date '+%F %T'` $me: $@" | tee -a "$log"
}

die() {
        echod "$@"
        exit 1
}

me="`basename $0 .sh`"

test -n "$log" || log="${0/.sh/.log}"

test -n "$path" || path='/data/tellerstats'
test -d "$path" || \
	die "no directory '$path'"

parms=''
for f in "$path"/iot-*.log ; do
	b="`basename "$f" .log`"
	test 'iot-server-' = "${b:0:11}" && continue
	b="${b:4}"
	read d n x<<<"`tail -n 1 "$f"`"
	read c fn <<<"`wc -l "$f"`"
	parms="$parms $b,$d,$n,$c"
done

py="${0/.sh/.py}"
test -f "$py" || \
	die "missing server '$py'"

python -u "$py" "$path/" $@ $parms >>"$log" 2>&1

