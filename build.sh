#!/bin/sh
set -e

for JOB in build_jobs/*.sh ; do
    echo "Running job: $(basename $JOB)"
    . "$(realpath $JOB)"
done