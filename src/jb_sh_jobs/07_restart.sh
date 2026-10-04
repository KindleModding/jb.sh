#!/bin/sh

if [ $RUN_MODE -eq 1 ] || [ $JAILBROKEN -eq 0 ]; then
    printf "You are jailbroken!\n" > /mnt/us/documents/JAILBROKEN.txt
    printf "(jb.sh $JB_SH_VERSION)\n" >> /mnt/us/documents/JAILBROKEN.txt
    printf "https://kindlemodding.org\n" >> /mnt/us/documents/JAILBROKEN.txt
    printf "https://hackerdude.tech\n" >> /mnt/us/documents/JAILBROKEN.txt
    printf "\n" >> /mnt/us/documents/JAILBROKEN.txt
    printf "$JB_HEADER" >> /mnt/us/documents/JAILBROKEN.txt
    printf "$JB_HEADER" > /var/local/jailbreak.txt

    ###
    # More OTA paranoia
    ###
    # Kill them asap
    killall otaupd -s SIGKILL s
    killall otav3 -s SIGKILL s

    # Delete .tmp.partial and .bin files
    rm -rf /mnt/us/*.tmp.partial
    rm -rf /mnt/us/*.bin
    rm -rf /mnt/base-us/*.tmp.partial
    rm -rf /mnt/base-us/*.bin
    rm -rf /mnt/userstore/*.tmp.partial
    rm -rf /mnt/userstore/*.bin

    log "Restarting Kindle..." # Necessary for sh_integration
    /var/local/kmc/bin/fbink -k # Clear screen
    /var/local/kmc/bin/fbink -y 3 -m -S 7 "Restarting Kindle"
    sleep 2 # So they can read what's about to happen
    reboot
fi