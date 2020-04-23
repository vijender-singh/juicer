#!/bin/bash -l
#SBATCH -p general
#SBATCH -q general
#SBATCH -c 1
#SBATCH --mem=5G

usegzip=$1
name=$2
name1=$3
name2=$4
ext=$5
ligation=$6
source juicer_config.config
groupname=$7

date
export usegzip=${usegzip}; export name=${name}; export name1=${name1}; export name2=${name2}; export ext=${ext}; export ligation=${ligation}; ${juiceDir}/scripts/countligations.sh
date
