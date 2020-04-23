#!/bin/bash -l
#SBATCH -p general
#SBATCH -q general
#SBATCH -c 1


date
source juicer_config.config
groupname=$1

# Experiment description
if [ -n "${about}" ]
then
    echo -ne 'Experiment description: ${about}; '
else
    echo -ne 'Experiment description: '
fi

# Get version numbers of all software
echo -ne "Juicer version $juicer_version;"
bwa 2>&1 | awk '\\\$1=="Version:"{printf(" BWA %s; ", \\\$2)}'
echo -ne "$threads threads; "
if [ -n "$splitme" ]
then
    echo -ne "splitsize $splitsize; "
fi
java -version 2>&1 | awk 'NR==1{printf("%s; ", \\\$0);}'
${juiceDir}/scripts/juicer_tools -V 2>&1 | awk '\\\$1=="Juicer" && \\\$2=="Tools"{printf("%s; ", \\\$0);}'

echo "$0 $@"
