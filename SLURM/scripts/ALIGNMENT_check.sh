#!/bin/bash
#SBATCH -p general
#SBATCH -p general

date
source juicer_config.config


f=$1
msg=$2
errorfile=$3


echo "Checking $f"
if [ ! -e $f ]
then
    echo $msg
    touch $errorfile
fi
date
