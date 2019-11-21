#!/usr/bin/env bash

dataset=$1
files_list=$2
tgt_dir=$3 # directory which will contain symlinks of the wav files. 

#TODO add exception error and check handling

if [ "$#" -ne 3 ]; then
    echo "You must enter exactly 3 command line arguments"
    echo "Usage: retrieve_wav.sh <dataset_type> <files_list> <tgt_dir>"
    exit 1
fi


if [ "$dataset" == "nchlt-xitsonga" ]; then


    path_ds=/scratch1/data/raw_data/NCHLT/nchlt_Xitsonga/audio

    mkdir -p ${tgt_dir}
    
    cat $files_list | while read l; do
        a=$(echo $l | cut -d'_' -f3)
        b=$(echo $l | cut -d'_' -f4)
        a_prime=$(echo $a | sed 's/[a-z]//g') # a bit farfetched. need to make it cleaner. 

        ln -s "${path_ds}/${a_prime}/nchlt_tso_${a}_${b}.wav" ${tgt_dir}/${l}.wav
        echo "Symlinked file ${l} to ${tgt_dir}."


        
    done


elif [ "$dataset" == "timit" ]; then

    path_ds=/scratch1/data/raw_data/TIMIT
    mkdir -p ${tgt_dir}
    
    cat $files_list | while read l; do
        a=$(echo $l | cut -d'_' -f1)
        b=$(echo $l | cut -d'_' -f2)

        cur_dir=$(find $path_ds -type d -name $a)
        find $cur_dir -type f -name ${b}.wav -exec ln -s {} ${tgt_dir}/${l}.wav \;
        echo "Symlinked file ${l} to ${tgt_dir}."

    done


    
else

    echo 'Please enter the dataset you want to take care of. Can be "timit" or "nchlt-xitsonga". --> exiting' && exit 1

fi
