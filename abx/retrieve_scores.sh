#!/usr/bin/env bash

set -e # exit on error

if [ $# != 2 ]; then
   echo "usage: ./retrieve_scores.sh <abx_dir> <abx_avg_name>"
   echo "e.g.:  ./run.sh EMIME abx_on_spk_by_lang.avg"
   exit 1;
fi



dir=$1
avg_name=${2}

for x in $dir/* ; do
    mkdir -p ${x}/log
    
    if [ -f ${x}/${avg_name} ]; then
        avg=$(cat ${x}/${avg_name})
        cond=$(echo `basename ${x}`)
        avg_percent=$(echo "$avg * 100" | bc)
        echo $avg_percent $cond
    fi
    
done
