#!/bin/bash -l
#SBATCH -p general
#SBATCH -q general
#SBATCH -c 1
#SBATCH --ntasks=1
#SBATCH --mem=5G

date
source juicer_config.config
groupname=$1
awkscript=$2

ls -l ${outputdir}/merged_sort.txt | awk '{printf("%s ", \\\$5)}' > $debugdir/dupcheck-${groupname}
ls -l ${outputdir}/merged_nodups.txt ${outputdir}/dups.txt ${outputdir}/opt_dups.txt | awk '{sum = sum + \\\$5}END{print sum}' >> $debugdir/dupcheck-${groupname}
awk -v debugdir=$debugdir -v queue=$queue -v groupname=$groupname -v dir=$outputdir '$awkscript' $debugdir/dupcheck-${groupname}
    date
