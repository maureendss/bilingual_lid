#!/usr/bin/env bash


if [[ $# -ne 4 ]]; then
    echo "Illegal number of parameters"
    exit 2
fi

abx_dir=$1
on_value=$2
by_value=$3
filt_value=$4

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
task=${abx_dir}/data_on_${on_value}_by_${by_value}_filt_${filt_value}.abx
distance=${abx_dir}/data_on_${on_value}_by_${by_value}_filt_${filt_value}.distance
score=${abx_dir}/data_on_${on_value}_by_${by_value}_filt_${filt_value}.score
analyze=${abx_dir}/data_on_${on_value}_by_${by_value}_filt_${filt_value}.csv

# generating task file
abx-task $item $task --verbose --on ${on_value} --by ${by_value} --filter="[sA != sX for (sA, sX) in zip(${filt_value}_A,${filt_value}_X)]"

# python task.py $item $task --verbose --on lang --filter="[sA != sX for (sA, sX) in zip(spk_A,spk_X)]"

# computing distances
abx-distance $features $task $distance --normalization 1 --njobs 5

# calculating the score
abx-score $task $distance $score

# collapsing the results
abx-analyze $score $task $analyze


python utils/average_abx_scores.py $analyze > $abx_dir/abx_on_${on_value}_by_${by_value}_filt_${filt_value}.avg
