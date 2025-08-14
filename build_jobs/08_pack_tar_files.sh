#!/bin/sh

# Yes - We pack files directly into the script
kmc_tar=

echo "#!/bin/sh" > build/jb.sh
echo "mkdir /tmp/kmc" >> build/jb.sh
echo "echo \"$(cat build/kmc.tar | xz -9 | base64 -w 0)\" | base64 -d | xz -d | tar xf - -C /tmp/kmc" >> build/jb.sh