mntroot ro
log "Done!"

if [ $RUN_MODE -eq 1 ] || [ $JAILBROKEN -eq 0 ]; then
printf "You are jailbroken!\n" > /mnt/us/documents/JAILBROKEN.txt
printf "(jb.sh $JB_SH_VERSION)\n" >> /mnt/us/documents/JAILBROKEN.txt
printf "https://kindlemodding.org\n" >> /mnt/us/documents/JAILBROKEN.txt
printf "https://hackerdude.tech\n" >> /mnt/us/documents/JAILBROKEN.txt
printf "\n" >> /mnt/us/documents/JAILBROKEN.txt
printf "$JB_HEADER" >> /mnt/us/documents/JAILBROKEN.txt
#printf "$JB_HEADER" >> /var/local/jailbreak.txt

log "Restarting gui..."
sleep 2 # So they can read what's about to happen
restart lab126_gui &
sleep 3 # Wait for it to stop
/var/local/kmc/bin/fbink -y 3 -m -S 7 "Restarting GUI"
/var/local/kmc/bin/fbink -y 4 -m -S 7 "Please Wait..."
/var/local/kmc/bin/fbink -y 16 -p -S 3 "(Kindles are slow lol)  "
/var/local/kmc/bin/fbink -y -6 -m -S 4 "(Error dialog is fine)"
/var/local/kmc/bin/fbink -y -5 -m -S 4 "(Just press close and keep waiting!)"

fi