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

# generating task file
abx-task $item $task --verbose --on lang

# computing distances
abx-distance $features $task $distance --normalization 1 --njobs 1

# calculating the score
abx-score $task $distance $score

# collapsing the results
abx-analyze $score $task $analyze


# Avergae results
l1=$(sed '2q;d' $analyze)
l2=$(sed '3q;d' $analyze)
num_1=$(echo $l1 | cut -d' ' -f 5)
num_2=$(echo $l2 | cut -d' ' -f 5)
score_1=$(echo $l1 | cut -d' ' -f 4)
score_2=$(echo $l2 | cut -d' ' -f 4)

if [ "$num_1" == "$num_2" ]; then
    echo |awk -v v1="$score_1" -v v2="$score_2" '{ print (v1+v2)/2 }' > $abx_dir/abx.avg
else
    echo |awk -v v1="$score_1" -v v2="$score_2" -v v3="${num_1}" -v v4="${num_2}"'{ print ((v1*v3)+(v2*v4))/(v3+v4) }' > $abx_dir/abx.avg
    echo "Careful - not same number of utterances between two pairs. " >> $abx_dir/abx.avg
    
    echo "Not same number of utterances -> couldn't compute average abx score."
fi
