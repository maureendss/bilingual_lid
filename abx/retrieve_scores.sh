#!/usr/bin/env bash

set -e # exit on error

if [ $# != 1 ]; then
   echo "usage: ./retrieve_scores.sh <abx_dir>"
   echo "e.g.:  ./run.sh EMIME"
   exit 1;
fi



dir=$1

for x in $dir/* ; do
    mkdir -p ${x}/log
    
    if [ -f ${x}/abx_byspk.avg ]; then
        avg=$(cat ${x}/abx_byspk.avg)
        cond=$(echo `basename ${x}`)
        echo $avg $cond
    fi
    
done
