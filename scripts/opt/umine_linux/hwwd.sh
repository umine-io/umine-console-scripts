#!/bin/bash

if [ ! -c "/dev/ttyUSB0" ]; then
    echo "Serial Watchdog is not connected!"
    exit 0
fi

stty -F /dev/ttyUSB0 speed 9600 -echo -echok -echoe
sleep 3
echo -en '\x12' > /dev/ttyUSB0

while true; do
    sleep 1
    echo -en '\x12' > /dev/ttyUSB0
done
