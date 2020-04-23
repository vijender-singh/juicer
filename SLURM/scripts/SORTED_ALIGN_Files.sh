#!/bin/bash -l
#SBATCH -p general
#SBATCH -q general

date
source juicer_config.config
groupname=$1
errorfile=$2

if [ -f "${errorfile}" ]
then
    echo "***! Found errorfile. Exiting."
    exit 1
fi
export LC_COLLATE=C

if [ -d $donesplitdir ]
then
    mv $donesplitdir/* $splitdir/.
fi

if ! sort --parallel=48 -S 32G -T ${tmpdir} -m -k2,2d -k6,6d -k4,4n -k8,8n -k1,1n -k5,5n -k3,3n $splitdir/*.sort.txt > $outputdir/merged_sort.txt
then
    echo "***! Some problems occurred somewhere in creating sorted align files."
    touch $errorfile
    exit 1
else
    echo "(-: Finished sorting all sorted files into a single merge."
fi

date
