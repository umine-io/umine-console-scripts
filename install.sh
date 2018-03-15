#!/bin/sh

if [ $(id -u) -ne "0" ]; then
    echo "You should be root user to install scripts!"
    exit 127
fi

install -d /opt/umine_linux
install -d /home/umine/.config/autostart

install -m 755 scripts/opt/umine_linux/*.sh /opt/umine_linux
install -o umine -m 640 scripts/home/umine/.config/autostart/umine.desktop /home/umine/.config/autostart
install -m 755 scripts/etc/rc.local /etc/rc.local
