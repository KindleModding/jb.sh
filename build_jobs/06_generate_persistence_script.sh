#!/bin/sh

for JOB in src/helpers/*.sh ; do
    echo "- Packing persistence.sh helper: $(basename $JOB)"
    echo "" >> build/kmc/persistence/persistence.sh
    echo "# Packed from $(basename $JOB)" >> build/kmc/persistence/persistence.sh
    echo "" >> build/kmc/persistence/persistence.sh
    cat "$(realpath $JOB)" >> build/kmc/persistence/persistence.sh
done

for JOB in src/persistence_jobs/*.sh ; do
    echo "- Packing persistence.sh job: $(basename $JOB)"
    echo "" >> build/kmc/persistence/persistence.sh
    echo "# Packed from $(basename $JOB)" >> build/kmc/persistence/persistence.sh
    echo "" >> build/kmc/persistence/persistence.sh
    cat "$(realpath $JOB)" >> build/kmc/persistence/persistence.sh
done