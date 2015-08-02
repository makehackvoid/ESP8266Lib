#!/bin/sh

me="`basename "$0" .sh`"
dir="`dirname "$0"`"
dir="`realpath "$dir"`"

port='11883'
log="$dir/iot-server-$port.log" path='/data/tellerstats' \
	"$dir/iot-server.sh" --port=$port
