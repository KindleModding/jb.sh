#!/bin/sh

# Yes - We pack files directly into the script
kmc_tar=$(cat build/kmc.tar | xz -9 | base64 -w 0)

echo "#!/bin/sh" > build/jb.sh
echo "mkdir /tmp/kmc" >> build/jb.sh
echo "echo \"$kmc_tar\" | base64 -d | xz -d | tar xf - -C /tmp/kmc" >> build/jb.sh