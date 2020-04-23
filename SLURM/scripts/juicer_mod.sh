#!/bin/bash
##########
#The MIT License (MIT)
#
# Copyright (c) 2015 Aiden Lab
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.
##########

# Juicer version 1.5.6
shopt -s extglob
juicer_version="1.5.7"
## Set the following variables to work with your system

## Read arguments
usageHelp="Usage: ${0##*/} [-g genomeID] [-d topDir] [-q queue] [-l long queue] [-s site]\n                 [-a about] [-R end] [-S stage] [-p chrom.sizes path]\n                 [-y restriction site file] [-z reference genome file]\n                 [-C chunk size] [-D Juicer scripts directory]\n                 [-Q queue time limit] [-L long queue time limit] [-b ligation] [-t threads]\n                 [-A account name] [-r] [-h] [-f] [-j]"
genomeHelp="* [genomeID] must be defined in the script, e.g. \"hg19\" or \"mm10\" (default \n  \"$genomeID\"); alternatively, it can be defined using the -z command"
dirHelp="* [topDir] is the top level directory (default\n  \"$topDir\")\n     [topDir]/fastq must contain the fastq files\n     [topDir]/splits will be created to contain the temporary split files\n     [topDir]/aligned will be created for the final alignment"
queueHelp="* [queue] is the queue for running alignments (default \"$queue\")"
longQueueHelp="* [long queue] is the queue for running longer jobs such as the hic file\n  creation (default \"$long_queue\")"
siteHelp="* \n  (default \"$site\")"
aboutHelp="* [about]: enter description of experiment, enclosed in single quotes"
shortHelp="* -r: use the short read version of the aligner, bwa aln\n  (default: long read, bwa mem)"
shortHelp2="* [end]: use the short read aligner on read end, must be one of 1 or 2 "
stageHelp="* [stage]: must be one of \"merge\", \"dedup\", \"final\", \"postproc\", or \"early\".\n    -Use \"merge\" when alignment has finished but the merged_sort file has not\n     yet been created.\n    -Use \"dedup\" when the files have been merged into merged_sort but\n     merged_nodups has not yet been created.\n    -Use \"final\" when the reads have been deduped into merged_nodups but the\n     final stats and hic files have not yet been created.\n    -Use \"postproc\" when the hic files have been created and only\n     postprocessing feature annotation remains to be completed.\n    -Use \"early\" for an early exit, before the final creation of the stats and\n     hic files"
pathHelp="* [chrom.sizes path]: enter path for chrom.sizes file"
siteFileHelp="* [restriction site file]: enter path for restriction site file (locations of\n  restriction sites in genome; can be generated with the script\n  misc/generate_site_positions.py)"
chunkHelp="* [chunk size]: number of lines in split files, must be multiple of 4\n  (default ${splitsize}, which equals $(awk -v ss=${splitsize} 'BEGIN{print ss/4000000}') million reads)"
scriptDirHelp="* [Juicer scripts directory]: set the Juicer directory,\n  which should have scripts/ references/ and restriction_sites/ underneath it\n  (default ${juiceDir})"
refSeqHelp="* [reference genome file]: enter path for reference sequence file, BWA index\n  files must be in same directory"
queueTimeHelp="* [queue time limit]: time limit for queue, i.e. -W 12:00 is 12 hours\n  (default ${queue_time})"
longQueueTimeHelp="* [long queue time limit]: time limit for long queue, i.e. -W 168:00 is one week\n  (default ${long_queue_time})"
ligationHelp="* [ligation junction]: use this string when counting ligation junctions"
threadsHelp="* [threads]: number of threads when running BWA alignment"
userHelp="* [account name]: user account name on cluster"
excludeHelp="* -f: include fragment-delimited maps in hic file creation"
justHelp="* -j: just exact duplicates excluded at dedupping step"
helpHelp="* -h: print this help and exit"

printHelpAndExit() {
    echo -e "$usageHelp"
    echo -e "$genomeHelp"
    echo -e "$dirHelp"
    echo -e "$queueHelp"
    echo -e "$longQueueHelp"
    echo -e "$siteHelp"
    echo -e "$aboutHelp"
    echo -e "$shortHelp"
    echo -e "$shortHelp2"
    echo -e "$stageHelp"
    echo -e "$pathHelp"
    echo -e "$siteFileHelp"
    echo -e "$refSeqHelp"
    echo -e "$chunkHelp"
    echo -e "$scriptDirHelp"
    echo -e "$queueTimeHelp"
    echo -e "$longQueueTimeHelp"
    echo -e "$ligationHelp"
    echo -e "$threadsHelp"
    echo -e "$userHelp"
    echo "$excludeHelp"
    echo "$helpHelp"
    exit "$1"
}

while getopts "h" opt; do
    case $opt in
	h) printHelpAndExit 0;;
	[?]) printHelpAndExit 1;;
    esac
done

# unique name for jobs in this run
groupname="a$(date +%s)"

source juicer_config.config
source create_directories.sh

# Add header containing command executed and timestamp:
jid=`sbatch -o $debugdir/head-%j.out -e $debugdir/head-%j.err -J "${groupname}_cmd" ${juiceDir}/scripts/HEADER.sh ${groupname} | egrep -o -e "\b[0-9]+$"`
headfile="${debugdir}/head-${jid}.out"

## Record if we failed while aligning, so we don't waste time on other jobs
## Remove file if we're relaunching Juicer
errorfile=${debugdir}/${groupname}_alignfail

if [ -f $errorfile ]
then
    rm $errorfile
fi


# Not in merge, dedup,  or final stage, i.e. need to split and align files.
if [ -z $merge ] && [ -z $final ] && [ -z $dedup ] && [ -z $postproc ]
then
    if [ "$nofrag" -eq 0 ]
    then
        echo -e "(-: Aligning files matching $fastqdir\n in queue $queue to genome $genomeID with site file $site_file"
    else
        echo -e "(-: Aligning files matching $fastqdir\n in queue $queue to genome $genomeID with no fragment delimited maps."
    fi

    ## Split fastq files into smaller portions for parallelizing alignment
    ## Do this by creating a text script file for the job on STDIN and then
    ## sending it to the cluster
    dependsplit="afterok"
    if [ ! $splitdirexists ]
    then
	       echo "(-: Created $splitdir and $outputdir."
           # -n tests if the variable is set
           if [ -n "$splitme" ]
           then
            for i in ${fastqdir}
            do
                # the two lines extract the file name by dropping path and file prefixes
                filename=$(basename $i)
                filename=${filename%.*}
                # if files are not .gz then $gzipped will be empty, -z tests if it is empty
                if [ -z "$gzipped" ]
                then
                    jid=`sbatch -o $debugdir/split-%j.out $debugdir/split-%j.err -J "${groupname}_split_${i}" ${juiceDir}/scripts/SPLITEND_fq.sh ${groupname} ${filename} ${i} | egrep -o -e "\b[0-9]+$" `

                else
                    jid=`sbatch -o $debugdir/split-%j.out $debugdir/split-%j.err -J "${groupname}_split_${i}" ${juiceDir}/scripts/SPLITEND_fq_gz.sh ${groupname} ${filename} ${i} | egrep -o -e "\b[0-9]+$"`
                fi

                dependsplit="$dependsplit:$jid"
                ## if we split files, the splits are named .fastq
                read1=${splitdir}"/*${read1str}*.fastq"
            done

	    srun -c 1 -p "$queue" -q "$queue" -t 1 -o $debugdir/wait-%j.out -e $debugdir/wait-%j.err -d $dependsplit -J "${groupname}_wait" sleep 1
        else
            cp -rs ${fastqdir} ${splitdir}
            wait
        fi
    else
        ## No need to re-split fastqs if they already exist
        echo -e "---  Using already created files in $splitdir\n"
	    # unzipped files will have .fastq extension, softlinked gz
        testname=$(ls -l ${splitdir} | awk '$9~/fastq$/||$9~/gz$/{print $9; exit}')

        if [ ${testname: -3} == ".gz" ]
        then
            read1=${splitdir}"/*${read1str}*.fastq.gz"
        else
	        read1=${splitdir}"/*${read1str}*.fastq"
        fi
    fi

    ## Launch job. Once split/move is done, set the parameters for the launch.
    echo "(-: Starting job to launch other jobs once splitting is complete"

    ## Loop over all read1 fastq files and create jobs for aligning read1,
    ## aligning read2, and merging the two. Keep track of merge names for final
    ## merge. When merge jobs successfully finish, can launch final merge job.
    ## ARRAY holds the names of the jobs as they are submitted
    ## Loop over all read1 fastq files and create jobs for aligning read1,
    ## aligning read2, and merging the two. Keep track of merge names for final
    ## merge. When merge jobs successfully finish, can launch final merge job.
    countjobs=0
    declare -a ARRAY
    declare -a JIDS
    declare -a TOUCH

    dependmerge="afterok"

    for i in ${read1}
    do
        ext=${i#*$read1str}
        name=${i%$read1str*}
        # these names have to be right or it'll break
        name1=${name}${read1str}
        name2=${name}${read2str}
        jname=$(basename "$name")${ext}
        usegzip=0
        if [ "${ext: -3}" == ".gz" ]
        then
            usegzip=1
        fi


    # count ligations
    jid=`sbatch -o $debugdir/count_ligation-%j.out -e $debugdir/count_ligation-%j.err -J "${groupname}_${jname}_Count_Ligation" ${juiceDir}/scripts/CNTLIG.sh ${usegzip} ${name} ${name1} ${name2} ${ext} ${ligation} ${groupname} | egrep -o -e "\b[0-9]+$"`

    dependcount="$jid"
	# align read1 fastq
	touchfile1=${tmpdir}/${jname}1
    jid=`sbatch -o $debugdir/align1-%j.out -e $debugdir/align1-%j.err -c $threads --mem=${alloc_mem} -J "${groupname}_align1_${jname}" ${juiceDir}/scripts/ALGNR1.sh ${groupname} $name $ext $errorfile $touchfile1 | egrep -o -e "\b[0-9]+$"`

	dependalign="afterok:$jid:$dependcount"
	# align read2 fastq
	touchfile2=${tmpdir}/${jname}2
    jid=`sbatch -o $debugdir/align2-%j.out -e $debugdir/align2-%j.err -c $threads --mem=${alloc_mem} -J "${groupname}_align2_${jname}" ${juiceDir}/scripts/ALGNR2.sh ${groupname} $name2 $ext $errorfile $touchfile2 | egrep -o -e "\b[0-9]+$"`




	dependalign="$dependalign:$jid"
    sortthreadstring="--parallel=$threads"

	touchfile3=${tmpdir}/${jname}3


    # wait for top two, merge
    # wait for top two, merge
    # wait for top two, merge
    jid=`sbatch -o $debugdir/merge-%j.out -e $debugdir/merge-%j.err -c $threads -d $dependalign -J "${groupname}_merge_${jname}" ${juiceDir}/scripts/MRGALL.sh ${groupname} ${touchfile1} ${touchfile2} ${name} ${name1} ${name2} ${ext} ${errorfile} ${sortthreadstring} | egrep -o -e "\b[0-9]+$"`

	dependmerge="${dependmerge}:${jid}"
	ARRAY[countjobs]="${groupname}_merge_${jname}"
	JIDS[countjobs]="${jid}"
	TOUCH[countjobs]="$touchfile3"
    countjobs=$(( $countjobs + 1 ))
done

    # list of all jobs. print errors if failed
    for (( i=0; i < $countjobs; i++ ))
    do
	f=${TOUCH[$i]}
	msg="***! Error in job ${ARRAY[$i]}  Type squeue -j ${JIDS[$i]} to see what happened"

	# check that alignment finished successfully
    jid=`sbatch -o $debugdir/aligncheck-%j.out -e $debugdir/aligncheck-%j.err -J "${groupname}_check" -d $dependmerge ${juiceDir}/scripts/ALIGNMENT_check.sh $f $msg $errorfile | egrep -o -e "\b[0-9]+$"`

	dependmergecheck="${dependmerge}:${jid}"
    done
fi  # Not in merge, dedup,  or final stage, i.e. need to split and align files.

# Not in final, dedup, or postproc
if [ -z $final ] && [ -z $dedup ] && [ -z $postproc ]
then
    if [ -z $merge ]
    then
	sbatch_wait="#SBATCH -d $dependmergecheck"
    else
        sbatch_wait=""
    fi

    # merge the sorted files into one giant file that is also sorted. jid=`sbatch <<- MRGSRT | egrep -o -e "\b[0-9]+$"

    jid=`sbatch -o $debugdir/fragmerge-%j.out -e $debugdir/fragmerge-%j.err --mem=80G -c 8 -J "${groupname}_fragmerge" -d $dependmergecheck ${juiceDir}/scripts/SORTED_ALIGN_Files.sh ${groupname} ${errorfile} | egrep -o -e "\b[0-9]+$"`
    dependmrgsrt="afterok:$jid"
fi

# Remove the duplicates from the big sorted file
if [ -z $final ] && [ -z $postproc ]
then
    if [ -z $dedup ]
    then
        sbatch_wait="-d $dependmrgsrt"
    else
        sbatch_wait=""
    fi
    # Guard job for dedup. this job is a placeholder to hold any job submitted after dedup.
    # We keep the ID of this guard, so we can later alter dependencies of inner dedupping phase.
    # After dedup is done, this job will be released.
    guardjid=`sbatch -o $debugdir/dedupguard-%j.out -e $debugdir/dedupguard-%j.err -J "${groupname}_dedup_guard" ${sbatch_wait} ${juiceDir}/scripts/DEDUPGUARD.sh | egrep -o -e "\b[0-9]+$"`

    dependguard="afterok:$guardjid"

    # if jobs succeeded, kill the cleanup job, remove the duplicates from the big sorted file
    jid=`sbatch -o $debugdir/dedup-%j.out -e $debugdir/dedup-%j.err -J "${groupname}_dedup" -d $dependmrgsrt ${juiceDir}/scripts/DEDUP.sh ${groupname} ${errorfile} ${guardjid} | egrep -o -e "\b[0-9]+$"`

    dependosplit="afterok:$jid"

    #Push dedup guard to run only after dedup is complete:
    scontrol update JobID=$guardjid dependency=afterok:$jid

    #Wait for all parts of split_rmdups to complete:
    jid=`sbatch -o $debugdir/post_dedup-%j.out -e $debugdir/post_dedup-%j.err -J "${groupname}_post_dedup" -d ${dependguard} ${juiceDir}/scripts/MSPLITWAIT.sh ${groupname} | egrep -o -e "\b[0-9]+$"`

    dependmsplit="afterok:$jid"
    sbatch_wait="#-d $dependmsplit"
else
    sbatch_wait=""
fi

if [ -z "$genomePath" ]
then
    #If no path to genome is give, use genome ID as default.
    genomePath=$genomeID
fi

#Skip if post-processing only is required
if [ -z $postproc ]
    then
    # Check that dedupping worked properly
    # in ideal world, we would check this in split_rmdups and not remove before we know they are correct
    awkscript='BEGIN{sscriptname = sprintf("%s/.%s_rmsplit.slurm", debugdir, groupname);}NR==1{if (NF == 2 && $1 == $2 ){print "Sorted and dups/no dups files add up"; printf("#!/bin/bash\n#SBATCH -o %s/dup-rm.out\n#SBATCH -e %s/dup-rm.err\n#SBATCH -p %s\n#SBATCH -q %s\n#SBATCH -J %s_msplit0\n#SBATCH -d singleton\n#SBATCH -t 1440\n#SBATCH -c 1\n#SBATCH --ntasks=1\ndate;\nrm %s/*_msplit*_optdups.txt; rm %s/*_msplit*_dups.txt; rm %s/*_msplit*_merged_nodups.txt;rm %s/split*;\ndate\n", debugdir, debugdir, queue, queue, groupname, dir, dir, dir, dir) > sscriptname; sysstring = sprintf("sbatch %s", sscriptname); system(sysstring);close(sscriptname); }else{print "Problem"; print "***! Error! The sorted file and dups/no dups files do not add up, or were empty."}}'
    jid=`sbatch -o $debugdir/dupcheck-%j.out -e $debugdir/dupcheck-%j.err -J "${groupname}_dupcheck" ${sbatch_wait} ${juiceDir}/scripts/DUPCHECK.sh $groupname $awkscript | egrep -o -e "\b[0-9]+$"`

    sbatch_wait="-d afterok:$jid"

    jid=`sbatch -o $debugdir/prestats-%j.out -e $debugdir/prestats-%j.err -J "${groupname}_prestats" ${sbatch_wait} ${juiceDir}/scripts/PRESTATS.sh $groupname $headfile | egrep -o -e "\b[0-9]+$"`

    sbatch_wait0="-d afterok:$jid"
    jid=`sbatch -o $debugdir/stats-%j.out -e $debugdir/stats-%j.err -J "${groupname}_stats" ${sbatch_wait0} ${juiceDir}/scripts/STATS.sh $groupname ${errorfile} | egrep -o -e "\b[0-9]+$"`

    sbatch_wait1="-d afterok:$jid"

    dependstats="afterok:$jid"
    jid=`sbatch -o $debugdir/stats30-%j.out -e $debugdir/stats30-%j.err  -J "${groupname}_stats" ${sbatch_wait0} ${juiceDir}/scripts/STATS30.sh | egrep -o -e "\b[0-9]+$"`

    dependstats30="afterok:$jid"
    sbatch_wait1="${sbatch_wait1}:$jid"
    # This job is waiting on deduping, thus sbatch_wait (vs sbatch_wait0 or 1)
    jid=`sbatch -o $debugdir/stats30-%j.out -e $debugdir/stats30-%j.err -J "${groupname}_stats" ${sbatch_wait} ${juiceDir}/scripts/CONCATFILES.sh ${groupname} | egrep -o -e "\b[0-9]+$"`

    # if early exit, we stop here, once the stats are calculated
    if [ ! -z "$earlyexit" ]
    then
	jid=`sbatch -o $debugdir/fincln1-%j.out -e $debugdir/fincln1-%j.err -J "${groupname}_prep_done" ${sbatch_wait1} ${juiceDir}/scripts/FINCLN1.sh ${groupname} | egrep -o -e "\b[0-9]+$"`

    echo "(-: Finished adding all jobs... Now is a good time to get that cup of coffee.."
	exit 0
    fi

    jid=`sbatch -o $debugdir/hic-%j.out -e $debugdir/hic-%j.err -J "${groupname}_hic" -d $dependstats ${juiceDir}/scripts/HIC.sh ${groupname} ${errorfile} | egrep -o -e "\b[0-9]+$"`

    dependhic="afterok:$jid"

    jid=`sbatch -o $debugdir/hic30-%j.out -e $debugdir/hic30-%j.err -J "${groupname}_hic30" -d ${dependstats30} ${juiceDir}/scripts/HIC30.sh ${groupname} ${errorfile} | egrep -o -e "\b[0-9]+$"`

    dependhic30="${dependhic}:$jid"
    sbatch_wait="-d $dependhic30"
else
    sbatch_wait=""
fi

if [ $isRice -eq 1 ] || [ $isVoltron -eq 1 ]
then
    if [  $isRice -eq 1 ]
    then
	sbatch_req="#SBATCH --gres=gpu:kepler:1"
    fi
    jid=`sbatch -o $debugdir/hiccups_wrap-%j.out -e $debugdir/hiccups_wrap-%j.er -J "${groupname}_hiccups_wrap" ${sbatch_wait} ${juiceDir}/scripts/HICCUPS.sh ${groupname} ${errorfile} | egrep -o -e "\b[0-9]+$"`
    dependhiccups="afterok:$jid"
else
    dependhiccups="afterok"
fi

jid=`sbatch -o $debugdir/arrowhead_wrap-%j.out -e $debugdir/arrowhead_wrap-%j.err -J "${groupname}_arrowhead_wrap" ${sbatch_wait} ${juiceDir}/scripts/ARROWS.sh ${groupname} ${errorfile} | egrep -o -e "\b[0-9]+$"`
dependarrows="${dependhiccups}:$jid"

jid=`sbatch -o $debugdir/fincln-%j.out -e $debugdir/fincln-%j.err -J "${groupname}_prep_done" -d $dependarrows ${juiceDir}/scripts/FINCLN1.sh ${groupname} | egrep -o -e "\b[0-9]+$"`

echo "(-: Finished adding all jobs... Now is a good time to get that cup of coffee.."
