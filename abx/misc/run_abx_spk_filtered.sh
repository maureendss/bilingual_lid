#!/usr/bin/env bash



#ONLY TO USE WHEN NO BILINGUAL SPEAKERS IN TEH TEST SET - otherwise doesn't make sense. 
if [[ $# -ne 1 ]]; then
    echo "Illegal number of parameters"
    exit 2
fi

abx_dir=$1

for x in ivectors.h5f ivectors.item; do
    if [ ! -f ${abx_dir}/${x} ]; then
        echo "${abx_dir}/${x} not present --> exiting" && exit 1;
    fi
done


set -e


# input files already here
item=${abx_dir}/ivectors.item
features=${abx_dir}/ivectors.h5f

# output files produced by ABX
task=${abx_dir}/data_spkfilt.abx
distance=${abx_dir}/data_spkfilt.distance
score=${abx_dir}/data_spkfilt.score
analyze=${abx_dir}/data_spkfilt.csv

# generating task file
abx-task $item $task --verbose --on lang --filter="[sA != sX for (sA, sX) in zip(spk_A,spk_X)]" 

#abx-task $item $task --verbose --on lang --filter="[sA != sX and sA != sB and sB != sX for (sA, sB, sX) in zip(spk_A,spk_B,spk_X)]" - can't use as otherwise we don't have symmetric reults between two langauges. 

# python task.py $item $task --verbose --on lang --filter="[sA != sX for (sA, sX) in zip(spk_A,spk_X)]"

# computing distances
abx-distance $features $task $distance --normalization 1 --njobs 5

# calculating the score
abx-score $task $distance $score

# collapsing the results
abx-analyze $score $task $analyze

# Average results
python utils/average_abx_scores.py $analyze > $abx_dir/abx_spkfilt.avg
