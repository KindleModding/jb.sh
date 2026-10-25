/bin/mount -o remount,ro /
/bin/mount -o exec /mnt/us # Remount as exec
log "Done"

if [ $RUN_MODE -eq 1 ] || [ $JAILBROKEN -eq 0 ]; then
    printf "You are jailbroken!\n" > /mnt/us/documents/JAILBROKEN.txt
    printf "(jb.sh $JB_SH_VERSION)\n" >> /mnt/us/documents/JAILBROKEN.txt
    printf "https://kindlemodding.org\n" >> /mnt/us/documents/JAILBROKEN.txt
    printf "https://hackerdude.tech\n" >> /mnt/us/documents/JAILBROKEN.txt
    printf "\n" >> /mnt/us/documents/JAILBROKEN.txt
    printf "$JB_HEADER" >> /mnt/us/documents/JAILBROKEN.txt
    printf "$JB_HEADER" > /var/local/jailbreak.txt

    log "Restarting Kindle..." # Necessary for sh_integration
    /var/local/kmc/bin/fbink -y 3 -m -S 7 "Restarting Kindle"
    sleep 2 # So they can read what's about to happen
    destroy_otas
    reboot
fi