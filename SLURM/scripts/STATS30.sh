#!/bin/bash -l
#SBATCH -p general
#SBATCH -q general
#SBATCH -c 1
#SBATCH --ntasks=1
#SBATCH --mem=50G

date
source juicer_config.config
groupname=$1

${juiceDir}/scripts/statistics.pl -s $site_file -l $ligation -o $outputdir/inter_30.txt -q 30 $outputdir/merged_nodups.txt
date
