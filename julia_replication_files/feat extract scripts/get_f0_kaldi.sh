#!/bin/bash


infile=$1
samplefreq=$2
outputdirectory=$3

if [ -z $infile ]; then
    echo "Warrning - no argument given, using testing file ..."
    infile=/mnt/matylda5/ifer/test.wav
fi


#kaldi_featbin=/mnt/matylda5/ifer/tools/kaldi/src/featbin

file=`basename ${infile%%.wav}`
fdir=`dirname $infile`

cat $infile | compute-and-process-kaldi-pitch-feats \
    --sample-frequency=$samplefreq "scp:echo $file -|" 'ark,t:-' \
    | copy-feats-to-htk --output-ext="kf0.fea" --output-dir=$outputdirectory 'ark,t:-'

echo "Kaldi F0 related features extracted to $outputdirectory/${file}.kf0.fea"