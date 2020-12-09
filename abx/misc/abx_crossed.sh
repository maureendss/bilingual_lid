#!/usr/bin/env bash


if [[ $# -ne 3 ]]; then
    echo "Illegal number of parameters"
    echo "usage: ./run_abx_crossed.sh <ivector_dir> <value A> <value B>"
    echo "e.g.:  ./run_abx_crossed.sh ivector_128_tr-train_mix_2_eng-fin_ts-test_eng-fin-bil lang spk"
    echo "Note: Value A will be more important if scores are closer to 100, otherwise if closer to 0, value B more important"
    exit 2
fi

abx_dir=$1
value_a=$2
value_b=$3


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
task=${abx_dir}/data_crossed_${value_a}_${value_b}.abx
distance=${abx_dir}/data_crossed_${value_a}_${value_b}.distance
score=${abx_dir}/data_crossed_${value_a}_${value_b}.score
analyze=${abx_dir}/data_crossed_${value_a}_${value_b}.csv
average=$abx_dir/abx_crossed_${value_a}_${value_b}.avg
# generating task file


if [ ! -f "$task" ]; then
    echo "computing task"
    abx-task $item $task --verbose --on ${value_a} --filter="[sA != sX and sB == sX for (sA, sB, sX) in zip(${value_b}_A,${value_b}_B,${value_b}_X)]"
fi

if [ ! -f "$distance" ]; then
    echo "computing distances"
    abx-distance $features $task $distance --normalization 1 --njobs 5
fi

if [ ! -f "$score" ]; then
    echo "computing score"
    # calculating the score
    abx-score $task $distance $score
fi

if [ ! -f "$analyze" ]; then
    echo " collapsing the results"
    abx-analyze $score $task $analyze
fi

if [ ! -f "$average" ]; then
    echo " Average results"

    python utils/average_abx_scores.py $analyze > $average
fi
