#!/usr/bin/env bash


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
task=${abx_dir}/data_acspk.abx
distance=${abx_dir}/data_acspk.distance
score=${abx_dir}/data_acspk.score
analyze=${abx_dir}/data_acspk.csv

# generating task file
abx-task $item $task --verbose --on lang --across spk

# computing distances
abx-distance $features $task $distance --normalization 1 --njobs 5

# calculating the score
abx-score $task $distance $score

# collapsing the results
abx-analyze $score $task $analyze



cat $analyze | awk -F' ' 'NR > 1 {sum+=$6*$7;  total+=$7} END {print sum / total}' > $abx_dir/abx_acspk.avg

