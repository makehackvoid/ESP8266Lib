#!/bin/sh

me="`basename "$0" .sh`"
dir="`dirname "$0"`"
dir="`realpath "$dir"`"

port='21883'
log="$dir/iot-server-$port.log" path='/data2/tmp/tellerstats' \
	"$dir/iot-server.sh" --port=$port
