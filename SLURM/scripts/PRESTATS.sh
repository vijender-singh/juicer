#!/bin/bash -l
#SBATCH -p general
#SBATCH -q general
#SBATCH -c 1
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=4G

date
source juicer_config.config
groupname=$1

export IBM_JAVA_OPTIONS="-Xmx1024m -Xgcthreads1"
export _JAVA_OPTIONS="-Xmx1024m -Xms1024m"

tail -n1 $headfile | awk '{printf"%-1000s\n", \\\$0}' > $outputdir/inter.txt
cat $splitdir/*.res.txt | awk -f ${juiceDir}/scripts/stats_sub.awk >> $outputdir/inter.txt
${juiceDir}/scripts/juicer_tools LibraryComplexity $outputdir inter.txt >> $outputdir/inter.txt
cp $outputdir/inter.txt $outputdir/inter_30.txt

date
