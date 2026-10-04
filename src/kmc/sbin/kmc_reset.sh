#!/bin/sh

if [ -f /usr/bin/otaupd.bck ]; then
    mv /usr/bin/otaupd.bck /usr/bin/otaupd
fi
if [ -f /usr/bin/otav3.bck ]; then
    mv /usr/bin/otav3.bck /usr/bin/otav3
fi