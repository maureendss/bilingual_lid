#!/usr/bin/env bash

set -e # exit on error

if [ $# != 1 ]; then
   echo "usage: ./run_byspk.sh <abx_dir>"
   echo "e.g.:  ./run.sh EMIME"
   exit 1;
fi



dir=$1

for x in $dir/* ; do
    mkdir -p ${x}/log
    
    if [ ! -f ${x}/abx_byspk.avg ]; then
        echo "Processing ${x}"
        sbatch --mem=5G -n 5 -o ${x}/log/abx_byspk.log ./abx_byspk.sh ${x}
    fi
    
done
