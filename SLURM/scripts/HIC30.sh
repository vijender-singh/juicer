#!/bin/bash -l
#SBATCH -p general
#SBATCH -q general
#SBATCH -c 1
#SBATCH --ntasks=1
#SBATCH --mem=60G

date
source juicer_config.config
groupname=$1
errorfile=$2

export IBM_JAVA_OPTIONS="-Xmx49152m -Xgcthreads1"
export _JAVA_OPTIONS="-Xmx49152m -Xms49152m"
date
    if [ -f "${errorfile}" ]
    then
        echo "***! Found errorfile. Exiting."
        exit 1
    fi
    if [ "$nofrag" -eq 1 ]
    then
    ${juiceDir}/scripts/juicer_tools pre -s $outputdir/inter_30.txt -g $outputdir/inter_30_hists.m -q 30 $outputdir/merged_nodups.txt $outputdir/inter_30.hic $genomePath
else
    ${juiceDir}/scripts/juicer_tools pre -f $site_file -s $outputdir/inter_30.txt -g $outputdir/inter_30_hists.m -q 30 $outputdir/merged_nodups.txt $outputdir/inter_30.hic $genomePath
fi
date
