#!/usr/bin/env bash


if [[ $# -ne 3 ]]; then
    echo "Illegal number of parameters"
    exit 2
fi

abx_dir=$1
on_value=$2
by_value=$3

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
task=${abx_dir}/data_on_${on_value}_by_${by_value}.abx
distance=${abx_dir}/data_on_${on_value}_by_${by_value}.distance
score=${abx_dir}/data_on_${on_value}_by_${by_value}.score
analyze=${abx_dir}/data_on_${on_value}_by_${by_value}.csv

# generating task file
abx-task $item $task --verbose --on ${on_value} --by ${by_value}

# computing distances
abx-distance $features $task $distance --normalization 1 --njobs 5

# calculating the score
abx-score $task $distance $score

# collapsing the results
abx-analyze $score $task $analyze


python utils/average_abx_scores.py $analyze > $abx_dir/abx_on_${on_value}_by_${by_value}.avg
