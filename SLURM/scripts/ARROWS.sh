#!/bin/bash -l
#SBATCH -p general
#SBATCH --mem-per-cpu=40G
#SBATCH -q general
#SBATCH --ntasks=1

date
source juicer_config.config
groupname=$1
errorfile=$2

    if [ -f "${errorfile}" ]
    then
        echo "***! Found errorfile. Exiting."
        exit 1
    fi
${juiceDir}/scripts/juicer_arrowhead.sh -j ${juiceDir}/scripts/juicer_tools -i $outputdir/inter_30.hic
date
