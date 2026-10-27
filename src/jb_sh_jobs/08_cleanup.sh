/bin/mount -o remount,ro /
/bin/mount -i -o remount,exec /mnt/us 2>/dev/null || /bin/mount -o exec /mnt/us # Remount as exec
log "Done"

if [ $RUN_MODE -eq 1 ] || [ $JAILBROKEN -eq 0 ]; then
    rm -f /mnt/base-us/documents/JAILBROKEN.txt /mnt/us/documents/JAILBROKEN.txt 2>/dev/null || true
    printf "You are jailbroken!\n" > /mnt/us/documents/JAILBROKEN.txt
    printf "(jb.sh $JB_SH_VERSION)\n" >> /mnt/us/documents/JAILBROKEN.txt
    printf "https://kindlemodding.org\n" >> /mnt/us/documents/JAILBROKEN.txt
    printf "https://hackerdude.tech\n" >> /mnt/us/documents/JAILBROKEN.txt
    printf "\n" >> /mnt/us/documents/JAILBROKEN.txt
    printf "$JB_HEADER" >> /mnt/us/documents/JAILBROKEN.txt
    printf "$JB_HEADER" > /var/local/jailbreak.txt

    log "Restarting Kindle..." # Necessary for sh_integration
    sync
    /var/local/kmc/bin/fbink -y 3 -m -S 7 "Restarting Kindle" 2>/dev/null || true
    sleep 2 # So they can read what's about to happen
    destroy_otas
    sync
    /sbin/reboot || /dev/.ovl/old_root/sbin/reboot 2>/dev/null || /dev/.ovl/lower/sbin/reboot 2>/dev/null || /sbin/reboot -f
    sleep 10
fi