#!/bin/bash
#SBATCH -p general
#SBATCH --mem-per-cpu=5G
#SBATCH -q general
#SBATCH -c 1
#SBATCH --ntasks=1

date
source juicer_config.config
groupname=$1
errorfile=$2
guardjid=$3


    if [ -f "${errorfile}" ]
    then
        echo "***! Found errorfile. Exiting."
        exit 1
    fi
squeue -u $USER -o "%A %T %j %E %R" | column -t
awk -v queue=general -v groupname=$groupname -v debugdir=$debugdir -v dir=$outputdir -v topDir=$topDir -v juicedir=$juiceDir -v site=$site -v genomeID=$genomeID -v genomePath=$genomePath -v user=$USER -v guardjid=$guardjid -v justexact=$justexact -f $juiceDir/scripts/split_rmdups.awk $outputdir/merged_sort.txt
##Schedule new job to run after last dedup part:
##Push guard to run after last dedup is completed:
##srun --ntasks=1 -c 1 -p "$queue" -t 1 -o ${debugdir}/dedup_requeue-%j.out -e ${debugdir}/dedup-requeue-%j.err -J "$groupname_msplit0" -d singleton echo ID: $ echo "\${!SLURM_JOB_ID}"; scontrol update JobID=$guardjid dependency=afterok:\$SLURM_JOB_ID
squeue -u $USER -o "%A %T %j %E %R" | column -t
date

scontrol release $guardjid
