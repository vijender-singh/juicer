#!/bin/bash

source juicer_config.config

## Check that fastq directory exists and has proper fastq files
## -d return TRUE if directory exists
## stat: The stat utility displays information about the file pointed to by file
## -t Display timestamps using the specified format
if [ ! -d "$topDir/fastq" ]; then
    echo "Directory \"$topDir/fastq\" does not exist."
    echo "Create \"$topDir/fastq\" and put fastq files to be aligned there."
    echo "Type \"juicer.sh -h\" for help"
    exit 1
else
    if stat -t ${fastqdir} >/dev/null 2>&1
    then
	echo "(-: Looking for fastq files...fastq files exist"
    else
	if [ ! -d "$splitdir" ]; then
	    echo "***! Failed to find any files matching ${fastqdir}"
	    echo "***! Type \"juicer.sh -h \" for help"
	    exit 1
	fi
    fi
fi

## Create output directory, only if not in postproc, dedup or final stages
## -d checks if the directory exists
if [[ -d "$outputdir" && -z "$final" && -z "$dedup" && -z "$postproc" ]]
then
    echo "***! Move or remove directory \"$outputdir\" before proceeding."
    echo "***! Type \"juicer.sh -h \" for help"
    exit 1
else
    if [[ -z "$final" && -z "$dedup" && -z "$postproc" ]]; then
        mkdir "$outputdir" || { echo "***! Unable to create ${outputdir}, check permissions." ; exit 1; }
    fi
fi

## Create split directory
if [ -d "$splitdir" ]; then
    splitdirexists=1
else
    mkdir "$splitdir" || { echo "***! Unable to create ${splitdir}, check permissions." ; exit 1; }
fi

## Create temporary directory, used for sort later
if [ ! -d "$tmpdir" ] && [ -z "$final" ] && [ -z "$dedup" ] && [ -z "$postproc" ]; then
    mkdir "$tmpdir"
    chmod 777 "$tmpdir"
fi

## Create output directory, used for reporting commands output
if [ ! -d "$debugdir" ]; then
    mkdir "$debugdir"
    chmod 777 "$debugdir"
fi


###*********---------------------------------------------*****##
###*********---------------------------------------------*****##
## Arguments have been checked and directories created. Now begins
## the real work of the pipeline
# If chunk size sent in, split. Otherwise check size before splitting

testname=$(ls -l ${fastqdir} | awk 'NR==1{print $9}')
if [ "${testname: -3}" == ".gz" ]
then
    read1=${splitdir}"/*${read1str}*.fastq.gz"
    gzipped=1
else
    read1=${splitdir}"/*${read1str}*.fastq"
fi
