#!/bin/sh

path='/data/tellerstats'

parms=''
for f in "$path"/iot-*.log ; do
	b="`basename "$f" .log`"
	b="${b:4}"
	read d n x<<<"`tail -n 1 "$f"`"
	read c fn <<<"`wc -l "$f"`"
	parms="$parms $b,$d,$n,$c"
done

python server.py $parms

