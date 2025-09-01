#!/bin/sh

for JOB in src/helpers/*.sh ; do
    echo "- Packing persistence.sh helper: $(basename $JOB)"
    echo "" >> build/kmc/system_patches/patch_system.sh
    echo "# Packed from $(basename $JOB)" >> build/kmc/system_patches/patch_system.sh
    echo "" >> build/kmc/system_patches/patch_system.sh
    cat "$(realpath $JOB)" >> build/kmc/system_patches/patch_system.sh
done

for JOB in src/persistence_jobs/*.sh ; do
    echo "- Packing persistence.sh job: $(basename $JOB)"
    echo "" >> build/kmc/system_patches/patch_system.sh
    echo "# Packed from $(basename $JOB)" >> build/kmc/system_patches/patch_system.sh
    echo "" >> build/kmc/system_patches/patch_system.sh
    cat "$(realpath $JOB)" >> build/kmc/system_patches/patch_system.sh
done