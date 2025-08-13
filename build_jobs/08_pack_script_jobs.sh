for JOB in src/jobs/*.sh ; do
    echo "- Packing jb.sh job: $(basename $JOB)"
    cat "$(realpath $JOB)" >> ./build/jb.sh
done