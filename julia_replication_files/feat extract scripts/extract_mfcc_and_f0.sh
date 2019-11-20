#!/bin/bash

# This script extracts MFCC using HCopy and (optionally) F0 using kaldi
# In order to run, you need HTK, Kaldi and get_f0_kaldi.sh

# To use, first give permission to execute by typing <chmod +x extract_mfcc_and_f0.sh> in the terminal
# To execute, call: ./extract_mfcc_and_f0.sh <wavfiledir> <configdir> 1 (set the last value to 0 if not using F0).

# Input arguments
wavdirectory=$1 # Directory were wav files are located
configpath=$2  # Full path to HCopy configuration file
withf0=$3      # 1 if you want F0, 0 if you don't

################ MFCC ##################
module load htk
#cd $wavdirectory
mfccoutputdir="./"`basename $wavdirectory`"_MFCC"
mkdir -p $wavdirectory/$mfccoutputdir
for file in `ls $wavdirectory/*.wav`; do HCopy -C $configpath $file $wavdirectory/$mfccoutputdir/`basename ${file%%.wav}`.htk; done


################# F0 ###################
module load kaldi
if [ $withf0 = 1 ]
then
	f0outputdir="./"`basename $wavdirectory`"_F0"
	mkdir -p $wavdirectory/$f0outputdir
	for file in `ls $wavdirectory/*.wav`; do ./get_f0_kaldi.sh $file 16000 $wavdirectory/$f0outputdir; done
fi