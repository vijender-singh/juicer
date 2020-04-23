#!/bin/bash -l
#SBATCH -p general
#SBATCH --mem=50G
#SBATCH -q general
#SBATCH --ntasks=1

export LC_COLLATE=C

date
source juicer_config.config
groupname=$1
touchfile1=$2
touchfile2=$3
name=$4
name1=$5
name2=$6
ext=$7
errorfile=$8
sortthreadstring=$9


if [ ! -f "${touchfile1}" ] || [ ! -f "${touchfile2}" ]
then
    echo "***! Error, cluster did not finish aligning ${jname}"
    touch $errorfile
    exit 1
fi
# sort read 1 aligned file by readname
sort $sortthreadstring -S 25G -T $tmpdir -k1,1f $name1$ext.sam > $name1${ext}_sort.sam
if [ \$? -ne 0 ]
then
    echo "***! Error while sorting $name1$ext.sam"
    touch $errorfile
    exit 1
else
    echo "(-: Sort read 1 aligned file by readname completed."
fi

# sort read 2 aligned file by readname
sort $sortthreadstring -S 25G -T $tmpdir -k1,1f $name2$ext.sam > $name2${ext}_sort.sam

if [ \$? -ne 0 ]
then
    echo "***! Error while sorting $name2$ext.sam"
    touch ${errorfile}
    exit 1
else
    echo "(-: Sort read 2 aligned file by readname completed."
fi

# remove header, add read end indicator toreadname
awk 'NF >= 11{\\\$1 = \\\$1"/1";print}' ${name1}${ext}_sort.sam > ${name1}${ext}_sort1.sam
awk 'NF >= 11{\\\$1 = \\\$1"/2";print}' ${name2}${ext}_sort.sam > ${name2}${ext}_sort1.sam

# merge the two sorted read end files
sort $sortthreadstring -S 25G -T $tmpdir -k1,1f -m $name1${ext}_sort1.sam $name2${ext}_sort1.sam > $name$ext.sam
if [ \$? -ne 0 ]
then
    echo "***! Failure during merge of read files"
    touch $errorfile
    exit 1
else
    echo "$name$ext.sam created successfully."
fi

# call chimeric_blacklist.awk to deal with chimeric reads; sorted file is sorted by read name at this point
touch ${name}${ext}_abnorm.sam ${name}${ext}_unmapped.sam ${name}${ext}_norm.txt
awk -v "fname1"=${name}${ext}_norm.txt -v "fname2"=${name}${ext}_abnorm.sam -v "fname3"=${name}${ext}_unmapped.sam -f $juiceDir/scripts/chimeric_blacklist.awk ${name}${ext}.sam

if [ \$? -ne 0 ]
then
    echo "***! Failure during chimera handling of $name${ext}"
    touch $errorfile
    exit 1
fi
# if any normal reads were written, find what fragment they
# correspond to and store that
# check if site file exists and if so write the fragment number
# even if nofrag set
# one is not obligated to provide a site file if nofrag set;
# but if one does, frag numbers will be calculated correctly
if [ -e "$name${ext}_norm.txt" ] && [ "$site" != "none" ] && [ -e "$site_file" ]
then
    ${juiceDir}/scripts/fragment.pl ${name}${ext}_norm.txt ${name}${ext}.frag.txt $site_file
elif [ "$site" == "none" ] || [ "$nofrag" -eq 1 ]
then
    awk '{printf("%s %s %s %d %s %s %s %d", \\\$1, \\\$2, \\\$3, 0, \\\$4, \\\$5, \\\$6, 1); for (i=7; i<=NF; i++) {printf(" %s",\\\$i);}printf("\n");}' $name${ext}_norm.txt > $name${ext}.frag.txt
else
    echo "***! No $name${ext}_norm.txt file created"
    touch $errorfile
    exit 1
fi
if [ \$? -ne 0 ]
then
    echo "***! Failure during fragment assignment of $name${ext}"
    touch $errorfile
    exit 1
fi
# sort by chromosome, fragment, strand, and position
sort $sortthreadstring -S 35G -T $tmpdir -k2,2d -k6,6d -k4,4n -k8,8n -k1,1n -k5,5n -k3,3n $name${ext}.frag.txt > $name${ext}.sort.txt
if [ \$? -ne 0 ]
then
    echo "***! Failure during sort of $name${ext}"
    touch $errorfile
    exit 1
else
    rm $name${ext}_norm.txt $name${ext}.frag.txt
    rm $name1$ext.sa* $name2$ext.sa* $name1${ext}_sort*.sam $name2${ext}_sort*.sam
fi
touch $touchfile3
date
