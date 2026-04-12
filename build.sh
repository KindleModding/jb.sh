#!/bin/sh
set -e

for JOB in build_jobs/*.sh ; do
    printf "Running job: $(basename $JOB)\n"
    . "$(realpath $JOB)"
done

printf "Done!\n"