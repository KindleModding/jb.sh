#!/bin/sh

# Yes - We pack files directly into the script

echo "#!/bin/sh" > build/jb.sh
echo "rm -rf /tmp/kmc" >> build/jb.sh
echo "mkdir /tmp/kmc" >> build/jb.sh
echo "echo \"Unpacking JB...\"" >> build/jb.sh
echo "echo '$(cat build/kmc.tar | xz -7 | openssl enc -base64)' | openssl enc -base64 -d | xz -d | tar xf - -C /tmp/kmc" >> build/jb.sh
echo "echo \"Done\"" >> build/jb.sh