#!/bin/sh

/opt/umine_linux/oc.sh

while [ ! -f /tmp/mining-session.tmp ]; do
    echo "Waiting for mining session..."
    sleep 1
done

byobu
