for JOB in src/jobs/*.sh ; do
    echo "- Packing jb.sh job: $(basename $JOB)"
    echo "" >> build/jb.sh
    echo "# Packed from $(basename $JOB)" >> build/jb.sh
    echo "" >> build/jb.sh
    cat "$(realpath $JOB)" >> build/jb.sh
done