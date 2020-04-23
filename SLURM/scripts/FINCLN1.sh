#!/bin/bash -l
#SBATCH -p general
#SBATCH --mem=5G
#SBATCH -q general
#SBATCH -c 1
#SBATCH --ntasks=1


date
source juicer_config.config
groupname=$1

date
export splitdir=${splitdir}; export outputdir=${outputdir}; export early=1; ${juiceDir}/scripts/check.sh
date
