#!/bin/sh

me="`basename "$0" .sh`"
dir="`dirname "$0"`"
dir="`realpath "$dir"`"

port='11883'
logdir="/data/tellerstats/iot-server-$port"
log="$logdir/iot-server-$port.log" path="$logdir" \
	"$dir/iot-server.sh" --port=$port
