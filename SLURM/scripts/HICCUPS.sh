#!/bin/bash -l
#SBATCH -p gpu
#SBATCH --mem-per-cpu=4G
#SBATCH -q general
#SBATCH --ntasks=1

date
source juicer_config.config
groupname=$1
errorfile=$2

module load  cuda/9.0

nvcc -V
    if [ -f "${errorfile}" ]
    then
        echo "***! Found errorfile. Exiting."
        exit 1
    fi
${juiceDir}/scripts/juicer_hiccups.sh -j ${juiceDir}/scripts/juicer_tools -i $outputdir/inter_30.hic -m ${juiceDir}/references/motif -g $genomeID
date
