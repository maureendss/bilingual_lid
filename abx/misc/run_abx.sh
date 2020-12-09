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
task=${abx_dir}/data.abx
distance=${abx_dir}/data.distance
score=${abx_dir}/data.score
analyze=${abx_dir}/data.csv
average=${abx_dir}abx_standard.avg

# generating task file
if [ ! -f "$task" ]; then
    echo "computing task"
    abx-task $item $task --verbose --on lang
fi

# computing distances
if [ ! -f "$distance" ]; then
    echo "computing distances"
    abx-distance $features $task $distance --normalization 1 --njobs 5
fi

if [ ! -f "$score" ]; then
    echo "computing score"
    # calculating the score
    abx-score $task $distance $score
fi



# collapsing the results
if [ ! -f "$analyze" ]; then
    echo " collapsing the results"
    abx-analyze $score $task $analyze
fi

# Average results
if [ ! -f "$average" ]; then
    echo " Average results"
    python utils/average_abx_scores.py $analyze > $average
fi
