#!/bin/sh

# Yes - We pack files directly into the script
kmc_tar=$(cat build/kmc.tar | gzip -9 | base64 -w 0)

rm build/jb.sh
touch build/jb.sh
printf "#!/bin/sh\n\n" >> build/jb.sh
echo "kmc_tar=\"$kmc_tar\"" >> build/jb.sh