#!/bin/sh

sleep 1 # Wait for keyboard to disappear
/var/local/kmc/bin/su -c "/var/local/kmc/bin/kpm --fbink $*"
sleep 2
/var/local/kmc/bin/su -c "/usr/bin/xrefresh -d :0.0"