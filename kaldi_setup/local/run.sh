 #!/usr/bin/env bash

# File for first steps on IVector Experiments


mfcc_conf=mfcc.original.conf # mfcc configuration file. The "original" one attempts to reproduce the settings in julia's experiments. 
stage=0
grad=true
nj=10
data=data/xitsonga_english #to chnge. Maybe make as complusory option?
raw_data=../../data/xitsonga_english
vad=false #not in original experiment. 

num_gauss=128


. ./cmd.sh
. ./path.sh
. utils/parse_options.sh

set -e # exit on error

#### Kaldi data preparation ####

if [ $stage -eq 0 ] || [ $stage -lt 0 ] && [ "${grad}" == "true" ]; then

    #Explain how get the raw data?
    
    for x in train_english train_xitsonga test_english test_xitsonga; do
        echo "**** Preparing ${x} data ****"
        ./local/data_prep/prepare_xitsonga_english.sh ${raw_data}/lists/${x}.txt ${raw_data}/wavs $data/${x}
    done;

    
fi


#### Replication Experiment 6 ####

# Feature Extraction #

if [ $stage -eq 1 ] || [ $stage -lt 1 ] && [ "${grad}" == "true" ]; then


    
    mfcc_conf=conf/mfcc.original.conf

    for x in train_english train_xitsonga test_english test_xitsonga; do
        steps/make_mfcc.sh --mfcc-config ${mfcc_conf} --cmd "${train_cmd}" --nj ${nj} \
                           ${data}/${x}
        #creating fake cmvn
        steps/compute_cmvn_stats.sh --fake ${data}/${x}
        

        if [ "${vad}" == "true" ]; then
            steps/compute_vad_decision.sh --cmd "$train_cmd" ${data}/${x}
        else
            echo "Creating a fake vad file"
            #create a fake vad.scp filled with 1s. 
            local/utils/create_nil_scp.py --filler 1 ${data}/${x}/feats.scp ${data}/${x}/vad
            touch ${data}/${x}/.fake_vad
        fi
        
        utils/validate_data_dir.sh --no-text ${data}/${x}

    done
    # If wanna add pitch for later experiments - have to run the make mfcc pitch script here instead. 
    # Same if wanna add CMN. Doesn't really make sense here anyway. .
fi 


if [ ! -d ${data}/train_bilingual ]; then
    #combine data dir to create train_bilingual - do itafter feature extraction so that don't have features twice.
    utils/combine_data.sh ${data}/train_bilingual_full ${data}/train_english ${data}/train_xitsonga
    #subset data dir to keep good size. 
    utils/subset_data_dir.sh --utt-list ../../data/xitsonga_english/lists/train_bilingual.txt ${data}/train_bilingual_full ${data}/train_bilingual
    utils/fix_data_dir.sh ${data}/train_bilingual
    utils/validate_data_dir.sh --no-text ${data}/train_bilingual
    
fi


if [ ! -d ${data}/test ]; then
    #combine data dir to create train_bilingual - do itafter feature extraction so that don't have features twice.
    utils/combine_data.sh ${data}/test ${data}/test_english ${data}/test_xitsonga
    utils/fix_data_dir.sh ${data}/test
    utils/validate_data_dir.sh --no-text ${data}/test
    
fi

#Need VAD here? Might be required by next steps. 

# UBM Training #

if [ $stage -eq 2 ] || [ $stage -lt 2 ] && [ "${grad}" == "true" ]; then

     #for train in train_english train_xitsonga train_bilingual; do 
    for train in train_english train_xitsonga train_bilingual; do 
        
    echo "*** Training diag UBM with $train dataset ***"
    lid/train_diag_ubm.sh --cmd "$train_cmd --mem 20G" \
                          --nj 15 --num-threads 8 \
                          --parallel_opts "" \
                          ${data}/${train} ${num_gauss} \
                          exp/ubm/diag_ubm_${num_gauss}_${train}

    #Same for full ubm - need to remove the cmn 
    echo "*** Training full UBM with $train dataset ***"
    lid/train_full_ubm.sh --nj 30 --cmd "$train_cmd" ${data}/${train} \
                          exp/ubm/diag_ubm_${num_gauss}_${train} exp/ubm/full_ubm_${num_gauss}_${train};

    # Alternatively, a diagonal UBM can replace the full UBM used above.
    # The preceding calls to train_diag_ubm.sh and train_full_ubm.sh
    # can be commented out and replaced with the following lines.

    # Note - maybe just use a diagnoal UBM?
    done
fi

if [ $stage -eq 3 ] || [ $stage -lt 3 ] && [ "${grad}" == "true" ]; then
    
    #for train in train_english train_xitsonga train_bilingual; do 
    for train in train_english train_xitsonga train_bilingual; do 
    
        
    lid/train_ivector_extractor.sh --cmd "$train_cmd --mem 2G" \
                                   --num-iters 5 --num_processes 1 exp/ubm/full_ubm_${num_gauss}_${train}/final.ubm ${data}/${train}  exp/ubm/extractor_full_ubm_${num_gauss}_${train}
    #stopped here

    done

fi


if [ $stage -eq 4 ] || [ $stage -lt 4 ] && [ "${grad}" == "true" ]; then

    test_data=test
    # use local version for blind test. TODO: see later if usefel (depending on how we test). 
    # local/lid/extract_ivectors.sh --cmd "$train_cmd --mem 3G" --nj 50 \
    #                         exp/ubm/extractor_full_ubm_${num_gauss}_${train} ${data}/${test_data} exp/ivectors/ivectors_${num_gauss}_tr-${train}_ts-${test_data}

    for train in train_english train_xitsonga train_bilingual; do
        lid/extract_ivectors.sh --cmd "$train_cmd --mem 3G" --nj 50 \
                                exp/ubm/extractor_full_ubm_${num_gauss}_${train} ${data}/${test_data} exp/ivectors/ivectors_${num_gauss}_tr-${train}_ts-${test_data}
    done
fi

# -------------------------------------------------------------------------
