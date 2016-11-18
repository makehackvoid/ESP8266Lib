#!/bin/sh

me="`basename "$0" .sh`"
dir="`dirname "$0"`"
dir="`realpath "$dir"`"
logdir='/data/tellerstats'

port='21883'
log="$logdir/iot-server-$port.log" path='/data2/tellerstats' \
	"$dir/iot-server.sh" --port=$port
