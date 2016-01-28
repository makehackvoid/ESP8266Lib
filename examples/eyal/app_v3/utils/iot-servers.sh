#!/bin/sh

echod() {
        echo "`date '+%F %T'` $me: $@"
}

die() {
        echod "$@"
        exit 1
}

me="`basename $0 .sh`"
dir="`dirname "$0"`"

nohup "$dir/iot-server1.sh" &
nohup "$dir/iot-server2.sh" &

exit 0
