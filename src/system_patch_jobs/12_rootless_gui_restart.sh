#!/bin/sh

if [ $MANPATCH -eq 1 ]; then # This is set in kmc/rootless_menu.sh, and is only ran when the user manually MANPATCHs it using "Get Started" in settings, on a rootless device
    log "Restarting GUI..." # Necessary for sh_integration
    sleep 2 # So they can read what's about to happen
    lipc-set-prop com.lab126.appmgrd start app://com.lab126.booklet.home
    lipc-set-prop com.lab126.appmgrd start app://com.lab126.KPPMainApp?view=KPP_HOME
    if [ -f "/etc/upstart/kppmainapp.conf" ] ; then
        log "Restart strategy 1"
        restart lab126_gui &
        sleep 3 # Wait for it to stop
    elif [ -f "/etc/upstart/acxe.conf" ] ; then
        log "Restart strategy 2"
        restart acxe & # On older devices restart the entire gui
        sleep 3 # Wait for it to stop
    else
        log "Restart strategy 3"
        telinit 5 &
        sleep 3 # Wait for it to stop
    fi
    /usr/sbin/eips -c # Helpapp likes to be stubborn at times
    /var/local/kmc/bin/fbink -y 3 -m -S 7 "Restarting GUI"
    /var/local/kmc/bin/fbink -y 4 -m -S 7 "Please Wait..."
    /var/local/kmc/bin/fbink -y 16 -p -S 3 "(Kindles are slow lol)  "
    /var/local/kmc/bin/fbink -y -6 -m -S 4 "(Error dialog is fine)"
    /var/local/kmc/bin/fbink -y -25 -m -S 4 "If you'd like to access the help menu, make an empty file named"
    /var/local/kmc/bin/fbink -y -22 -m -S 4 "ACCESS_HELPAPP"
    /var/local/kmc/bin/fbink -y -20 -m -S 4 "in the USB root of your Kindle!"
    /var/local/kmc/bin/fbink -y -5 -m -S 4 "(Just press close and keep waiting!)"
fi