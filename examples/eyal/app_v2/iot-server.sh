#!/bin/sh

test -n "$path" || path='/data/tellerstats'
test -n "$log" || log="${0/.sh/.log}"

parms=''
for f in "$path"/iot-*.log ; do
	b="`basename "$f" .log`"
	b="${b:4}"
	read d n x<<<"`tail -n 1 "$f"`"
	read c fn <<<"`wc -l "$f"`"
	parms="$parms $b,$d,$n,$c"
done

python -u "${0/.sh/.py}" "$path/" $@ $parms 2>&1 | tee -a "$log"

