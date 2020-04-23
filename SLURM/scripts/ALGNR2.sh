#!/bin/bash -l
#SBATCH -p general
#SBATCH -q general
#SBATCH -n 1
#SBATCH --ntasks=1
#SBATCH --threads-per-core=1

date
source juicer_config.config
groupname=$1
name2=$2
ext=$3
errorfile=$4
touchfile2=$5

date
# Align read2
if [ -n "$shortread" ] || [ "$shortreadend" -eq 2 ]
then
    echo 'Running command bwa aln $threadstring -q 15 $refSeq $name2$ext > $name2$ext.sai && bwa samse $refSeq $name2$ext.sai $name2$ext > $name2$ext.sam '
    srun --ntasks=1 bwa aln $threadstring -q 15 $refSeq $name2$ext > $name2$ext.sai && srun --ntasks=1 bwa samse $refSeq $name2$ext.sai $name2$ext > $name2$ext.sam
    if [ \$? -ne 0 ]
    then
        touch $errorfile
        exit 1
    else
        touch $touchfile2
        echo "(-: Short align of $name2$ext.sam done successfully"
    fi
else
    echo 'Running command bwa mem $threadstring $refSeq $name2$ext > $name2$ext.sam'
    srun --ntasks=1 bwa mem $threadstring $refSeq $name2$ext > $name2$ext.sam
    if [ \$? -ne 0 ]
    then
        touch $errorfile
        exit 1
    else
        touch $touchfile2
        echo "(-: Mem align of $name2$ext.sam done successfully"
    fi
fi
date
