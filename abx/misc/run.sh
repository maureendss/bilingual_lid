#!/usr/bin/env bash

set -e # exit on error

if [ $# != 1 ]; then
   echo "usage: ./run.sh <abx_dir>"
   echo "e.g.:  ./run.sh kaldi_exps/EMIME"
   exit 1;
fi



dir=$1

for x in $dir/*; do

    mkdir -p ${x}/log

   if [ ! -f ${x}/abx.avg ]; then
        sbatch --mem=5G -n 5 -o ${x}/log/abx_standard.log ./run_abx.sh ${x}
   fi

    
done
