#!/bin/bash -l
#SBATCH -p general
#SBATCH -q general
#SBATCH -c 1
#SBATCH --mem=5G


date
source juicer_config.config
groupname=$1
filename=$2
i=$3


echo "Split file: $filename"
szcat $i | split -a 3 -l $splitsize -d --additional-suffix=.fastq - $splitdir/$filename
date
