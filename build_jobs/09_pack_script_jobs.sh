#!/bin/sh

for JOB in src/helpers/*.sh ; do
    echo "- Packing jb.sh helper: $(basename $JOB)"
    echo "" >> build/jb.sh
    echo "# Packed from $(basename $JOB)" >> build/jb.sh
    echo "" >> build/jb.sh
    cat "$(realpath $JOB)" >> build/jb.sh
done

for JOB in src/jb_sh_jobs/*.sh ; do
    echo "- Packing jb.sh job: $(basename $JOB)"
    echo "" >> build/jb.sh
    echo "# Packed from $(basename $JOB)" >> build/jb.sh
    echo "" >> build/jb.sh
    cat "$(realpath $JOB)" >> build/jb.sh
done