#!/usr/bin/env bash

set -e # exit on error

if [ $# != 3 ]; then
    echo "usage: ./run_crossed.sh <abx_dir> <value A> <value B>"
    echo "e.g.:  ./run_crossed.sh EMIME lang spk"
    echo "Note: Value A will be more important if scores are closer to 100, otherwise if closer to 0, value B more important"

   exit 1;
fi



dir=$1
value_a=$2
value_b=$3


for x in $dir/ivec* ; do
    mkdir -p ${x}/log
    
    if [ ! -f ${x}/abx_crossed_${value_a}_${value_b}.avg ]; then
        echo "Processing ${x}"
        sbatch --mem=20G -n 5 -o ${x}/log/abx_crossed_${value_a}_${value_b}.log misc/abx_crossed.sh ${x} ${value_a} ${value_b}
        
    fi
    
done
