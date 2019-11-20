#!/usr/bin/env bash

# File for first steps on IVector Experiments


mfcc_conf=mfcc.original.conf # mfcc configuration file. The "original" one attempts to reproduce the settings in julia's experiments. 
stage=0
grad=true
nj=10
data=data/train #to chnge. Maybe make as complusory option?



. ./cmd.sh
. ./path.sh
. utils/parse_options.sh

set -e # exit on error

#### Kaldi data preparation ####

if [ $stage -eq 0 ] || [ $stage -lt 0 ] && [ "${grad}" == "true" ]; then

    # ...
    # Put data preparation scripts here
    # ...
fi


#### Replication Experiment 6 ####

mfcc_conf=mfcc.original.conf

# Feature Extraction #

steps/make_mfcc.sh --conf ${mfcc_conf} --cmd "${train_cmd}" --nj ${nj} \
                   ${train_data}
utils/fix_data_dir.sh ${train_data}
# If wanna add pitch for later experiments - have to run the make mfcc pitch script here instead. 
# Same if wanna add CMN. Doesn't really make sense here anyway. .

#Need VAD here? Might be required by next steps. 

# UBM Training #



num_gauss=128
sid/train_diag_ubm.sh --cmd "$train_cmd --mem 20G" \
                      --nj 16 --num-threads 8 --apply-cmn false \
                      ${train_data} ${num_gauss} \
                      exp/ubm/diag_ubm_${num_gauss}_${`basename $train_data`}

#Same for full ubm - need to remove the cmn 

lid/train_full_ubm.sh --nj 30 --cmd "$train_cmd" ${train_data} \
  exp/ubm/diag_ubm_${num_gauss}_${`basename $train_data`} exp/ubm/full_ubm_${num_gauss}_${`basename $train_data`}

# Alternatively, a diagonal UBM can replace the full UBM used above.
# The preceding calls to train_diag_ubm.sh and train_full_ubm.sh
# can be commented out and replaced with the following lines.

# Note - maybe just use a diagnoal UBM?


lid/train_ivector_extractor.sh --cmd "$train_cmd --mem 2G" \
  --num-iters 5 exp/ubm/full_ubm_${num_gauss}_${`basename $train_data`}/final.ubm ${train_data} \
  exp/ubm/extractor_full_ubm_${num_gauss}_${`basename $train_data`}
#stopped here


lid/extract_ivectors.sh --cmd "$train_cmd --mem 3G" --nj 50 \
   exp/extractor_2048 data/train exp/ivectors_train



# -------------------------------------------------------------------------
## Careful below is just copy of https://github.com/kaldi-asr/kaldi/blob/master/egs/lre/v1/run.sh. The SID directory comes from https://github.com/kaldi-asr/kaldi/tree/master/egs/sre08/v1

  # note, we're using the speaker-id version of the train_diag_ubm.sh script, which
  # uses double-delta instead of SDC features.  We train a 256-Gaussian UBM; this
  # has to be tuned.
  sid/train_diag_ubm.sh --nj 30 --cmd "$train_cmd" data/train_5k_novtln 256 \
    exp/diag_ubm_vtln
  lid/train_lvtln_model.sh --mfcc-config conf/mfcc_vtln.conf --nj 30 --cmd "$train_cmd" \
     data/train_5k_novtln exp/diag_ubm_vtln exp/vtln



# I-Vector Extraction #
