#!/bin/sh

/opt/umine_linux/oc.sh

if [ -f "/etc/default/umine" ]; then
    . /etc/defualt/umine
fi

if [ x"${UMINE_WEB_UI}" = x"1" ]; then
    chromium-browser --kiosk /home/umine/Documents/index.html
else
    while [ ! -f /tmp/mining-session.tmp ]; do
        echo "Waiting for mining session..."
        sleep 1
    done

    byobu
fi
