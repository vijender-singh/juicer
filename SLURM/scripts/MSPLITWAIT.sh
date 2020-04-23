#!/bin/bash -l
#SBATCH -p general
#SBATCH -q general
#SBATCH -c 1
#SBATCH --ntasks=1


date
source juicer_config.config
groupname=$1

rm -Rf $tmpdir;
find $debugdir -type f -size 0 | xargs rm
squeue -u $USER -o "%A %T %j %E %R" | column -t
date
