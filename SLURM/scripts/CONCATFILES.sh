#!/bin/bash -l
#SBATCH -p general
#SBATCH -t general
#SBATCH -c 1
#SBATCH --ntasks=1
#SBATCH --mem=50G

date
source juicer_config.config
groupname=$1

cat $splitdir/*_abnorm.sam > $outputdir/abnormal.sam
cat $splitdir/*_unmapped.sam > $outputdir/unmapped.sam
awk -f ${juiceDir}/scripts/collisions.awk $outputdir/abnormal.sam > $outputdir/collisions.txt
        #dedup collisions here
date
