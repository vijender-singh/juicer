#!/bin/bash -l
#SBATCH -p general
#SBATCH -t general
#SBATCH -c 1
#SBATCH --ntasks=1
#SBATCH --mem=50G

date
source juicer_config.config
groupname=$1
errorfile=$2


if [ -f "${errorfile}" ]
then
    echo "***! Found errorfile. Exiting."
    exit 1
fi
${juiceDir}/scripts/statistics.pl -s $site_file -l $ligation -o $outputdir/inter.txt -q 1 $outputdir/merged_nodups.txt

date
