#!/usr/bin/env bash

set -e # exit on error

if [ $# != 3 ]; then
   echo "usage: ./run_byspk.sh <abx_dir>"
   echo "e.g.:  ./run.sh EMIME"
   exit 1;
fi



dir=$1
on_value=$2
by_value=$3


for x in $dir/* ; do
    mkdir -p ${x}/log
    
    if [ ! -f ${x}/abx_on_${on_value}_by_${by_value}.avg ]; then
        echo "Processing ${x}"
        sbatch --mem=20G -n 5 -o ${x}/log/abx_on_${on_value}_by_${by_value}.log misc/run_abx_on_x_by_y.sh ${x} ${on_value} ${by_value}
        
    fi
    
done
