#!/bin/bash -l
#SBATCH -p general
#SBATCH -q general
#SBATCH -n 1
#SBATCH --ntasks=1
#SBATCH --threads-per-core=1

date
source juicer_config.config
groupname=$1
name1=$2
ext=$3
errorfile=$4
touchfile1=$5

# Align read1
date
if [ -n "$shortread" ] || [ "$shortreadend" -eq 1 ]
then
    echo 'Running command bwa aln $threadstring -q 15 $refSeq $name1$ext > $name1$ext.sai && bwa samse $refSeq $name1$ext.sai $name1$ext > $name1$ext.sam'
    srun --ntasks=1 bwa aln $threadstring -q 15 $refSeq $name1$ext > $name1$ext.sai && srun --ntasks=1 bwa samse $refSeq $name1$ext.sai $name1$ext > $name1$ext.sam
    if [ \$? -ne 0 ]
    then
        touch $errorfile
        exit 1
    else
        touch $touchfile1
        echo "(-: Short align of $name1$ext.sam done successfully"
        fi
else
    echo 'Running command bwa mem $threadstring $refSeq $name1$ext > $name1$ext.sam '
    srun --ntasks=1 bwa mem $threadstring $refSeq $name1$ext > $name1$ext.sam
    if [ \$? -ne 0 ]
    then
        touch $errorfile
        exit 1
    else
        touch $touchfile1
        echo "(-: Mem align of $name1$ext.sam done successfully"
    fi
fi
date
