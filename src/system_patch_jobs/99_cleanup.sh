mntroot ro
log "Done!"

if [ $RUN_MODE -eq 1 ] || [ $JAILBROKEN -eq 0 ]; then
log "Restarting gui..."
sleep 2 # So they can read what's about to happen
restart lab126_gui &
sleep 3 # Wait for it to stop
/var/local/kmc/bin/fbink -y 3 -m -S 7 "Restarting GUI"
/var/local/kmc/bin/fbink -y 4 -m -S 7 "Please Wait..."
/var/local/kmc/bin/fbink -y 16 -p -S 3 "(Kindles are slow lol)  "
/var/local/kmc/bin/fbink -y -6 -m -S 4 "(Error dialog is fine)"
/var/local/kmc/bin/fbink -y -5 -m -S 4 "(Just press close and keep waiting!)"
echo "You are jailbroken!" > /mnt/us/JAILBROKEN.txt
echo "Hackerdude was here" >> /mnt/us/JAILBROKEN.txt
echo "https://hackerdude.tech" >> /mnt/us/JAILBROKEN.txt
echo "https://kindlemodding.org" >> /mnt/us/JAILBROKEN.txt
fi