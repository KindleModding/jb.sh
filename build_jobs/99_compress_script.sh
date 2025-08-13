script_compressed=$(cat build/jb.sh | xz -9 | base64 -w 0)

echo "#!/bin/sh" > build/jb_compressed.sh
echo "echo \"$script_compressed\" | base64 -d | xz -d | sh" >> build/jb_compressed.sh