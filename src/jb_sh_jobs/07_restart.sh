#!/bin/sh

if [ $RUN_MODE -eq 1 ] || [ $JAILBROKEN -eq 0 ]; then
    printf "You are jailbroken!\n" > /mnt/us/documents/JAILBROKEN.txt
    printf "(jb.sh $JB_SH_VERSION)\n" >> /mnt/us/documents/JAILBROKEN.txt
    printf "https://kindlemodding.org\n" >> /mnt/us/documents/JAILBROKEN.txt
    printf "https://hackerdude.tech\n" >> /mnt/us/documents/JAILBROKEN.txt
    printf "\n" >> /mnt/us/documents/JAILBROKEN.txt
    printf "$JB_HEADER" >> /mnt/us/documents/JAILBROKEN.txt
    printf "$JB_HEADER" > /var/local/jailbreak.txt

    # Delete .tmp.partial and .bin files
    destroy_otas

    log "Restarting Kindle..." # Necessary for sh_integration
    /var/local/kmc/bin/fbink -k # Clear screen
    /var/local/kmc/bin/fbink -y 3 -m -S 7 "Restarting Kindle"
    sleep 2 # So they can read what's about to happen
    reboot
fi