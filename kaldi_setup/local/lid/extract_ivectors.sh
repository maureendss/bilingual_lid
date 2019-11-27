#!/bin/bash

# Copyright     2013  Daniel Povey
#               2014  David Snyder
# Apache 2.0.


#MDS: modified for more flexibility in features-specific options (cmvn/deltas, vad)


# This script extracts iVectors for a set of utterances, given
# features and a trained iVector extractor.

# Begin configuration section.
nj=30
cmd="run.pl"
stage=0
num_gselect=20 # Gaussian-selection using diagonal model: number of Gaussians to select
min_post=0.025 # Minimum posterior to use (posteriors below this are pruned out)
posterior_scale=1.0 # This scale helps to control for successve features being highly
                    # correlated.  E.g. try 0.1 or 0.3.
# End configuration section.


#MDS: features-specific config
cmvn=false
deltas=false
deltas_sdc=false #either deltas or deltas_sdc or none but both not compatible.
vad=false
 

echo "$0 $@"  # Print the command line for logging

if [ -f path.sh ]; then . ./path.sh; fi
. parse_options.sh || exit 1;


if [ $# != 3 ]; then
  echo "Usage: $0 <extractor-dir> <data> <ivector-dir>"
  echo " e.g.: $0 exp/extractor_2048_male data/train_male exp/ivectors_male"
  echo "main options (for others, see top of script file)"
  echo "  --config <config-file>                           # config containing options"
  echo "  --cmd (utils/run.pl|utils/queue.pl <queue opts>) # how to run jobs."
  echo "  --num-iters <#iters|10>                          # Number of iterations of E-M"
  echo "  --nj <n|10>                                      # Number of jobs (also see num-processes and num-threads)"
  echo "  --num-threads <n|8>                              # Number of threads for each process"
  echo "  --stage <stage|0>                                # To control partial reruns"
  echo "  --num-gselect <n|20>                             # Number of Gaussians to select using"
  echo "                                                   # diagonal model."
  echo "  --min-post <min-post|0.025>                      # Pruning threshold for posteriors"
  exit 1;
fi

srcdir=$1
data=$2
dir=$3

for f in $srcdir/final.ie $srcdir/final.ubm $data/feats.scp $data/utt2lang; do
  [ ! -f $f ] && echo "No such file $f" && exit 1;
done

# Set various variables.
mkdir -p $dir/log
sdata=$data/split$nj;
utils/split_data.sh $data $nj || exit 1;


## Set up features.

#------------------------------------
#MDS - Beginning of features-special options.
if [ "$deltas" == "true" ] && [ "$deltas_sdc" == "true" ]; then
    echo "Simple deltas (--deltas) and SDC deltas (--deltas_sdc) are not compatible options. --> Exiting" && exit 1 ;
fi

feats="ark,s,cs:copy-feats scp:$sdata/JOB/feats.scp ark:- |"

if [ "${deltas}" == "true" ]; then
    delta_opts=`cat $fgmm_model/delta_opts 2>/dev/null`
    feats="$feats add-deltas $delta_opts ark:- ark:- |"
fi

if [ "${cmvn}" == "true" ]; then
    feats="$feats apply-cmvn-sliding ark:- ark:- |"
fi

if [ "${deltas_sdc}" == "true" ]; then
    feats="$feats add-deltas-sdc ark:- ark:- |"
fi

if [ "${vad}" == "true" ]; then
    if [ ! -f $sdata/JOB/vad.scp ]; then echo "No $sdata/JOB/vad.scp. Exiting." && exit 1; fi
    feats="$feats select-voiced-frames ark:- scp,s,cs:$sdata/JOB/vad.scp ark:- |"
fi

echo "--> Feats command: $feats"
#------------------------------------    



if [ $stage -le 0 ]; then
  echo "$0: extracting iVectors"
  dubm="fgmm-global-to-gmm $srcdir/final.ubm -|"

  $cmd JOB=1:$nj $dir/log/extract_ivectors.JOB.log \
    gmm-gselect --n=$num_gselect "$dubm" "$feats" ark:- \| \
    fgmm-global-gselect-to-post --min-post=$min_post $srcdir/final.ubm "$feats" \
      ark,s,cs:- ark:- \| scale-post ark:- $posterior_scale ark:- \| \
    ivector-extract --verbose=2 $srcdir/final.ie "$feats" ark,s,cs:- \
      ark,scp,t:$dir/ivector.JOB.ark,$dir/ivector.JOB.scp || exit 1;
fi

if [ $stage -le 1 ]; then
  echo "$0: combining iVectors across jobs"
  for j in $(seq $nj); do cat $dir/ivector.$j.scp; done >$dir/ivector.scp || exit 1;
fi

if [ $stage -le 2 ]; then
  # Be careful here: the language-level iVectors are now length-normalized,
  # even if they are otherwise the same as the utterance-level ones.
  echo "$0: computing mean of iVectors for each speaker and length-normalizing"
  $cmd $dir/log/speaker_mean.log \
    ivector-normalize-length scp:$dir/ivector.scp  ark:- \| \
    ivector-mean "ark:utils/spk2utt_to_utt2spk.pl $data/utt2lang|" ark:- ark:- ark,t:$dir/num_utts.ark \| \
    ivector-normalize-length ark:- ark,scp:$dir/lang_ivector.ark,$dir/lang_ivector.scp || exit 1;
fi
