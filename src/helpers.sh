###
# Define logging function
###
POS=1
log() {
  echo "${1}" >> /mnt/us/jb.sh.log
  eips 0 $POS "${1}"
  echo "${1}"
  POS=$((POS+1))
}

###
# Helper functions
###
make_mutable() {
        local my_path="${1}"
        # NOTE: Can't do that on symlinks, hence the hoop-jumping...
        if [ -d "${my_path}" ] ; then
                find "${my_path}" -type d -exec chattr -i '{}' \;
                find "${my_path}" -type f -exec chattr -i '{}' \;
        elif [ -f "${my_path}" ] ; then
                chattr -i "${my_path}"
        fi
}

make_immutable() {
        local my_path="${1}"
        if [ -d "${my_path}" ] ; then
                find "${my_path}" -type d -exec chattr +i '{}' \;
                find "${my_path}" -type f -exec chattr +i '{}' \;
        elif [ -f "${my_path}" ] ; then
                chattr +i "${my_path}"
        fi
}