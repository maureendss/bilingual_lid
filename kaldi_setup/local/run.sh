 #!/usr/bin/env bash

# File for first steps on IVector Experiments


mfcc_conf=mfcc.original.conf # mfcc configuration file. The "original" one attempts to reproduce the settings in julia's experiments. 
stage=0
grad=true
nj=10
data=data/xitsonga_english #to chnge. Maybe make as complusory option?
raw_data=../../data/xitsonga_english
no_speaker_info=false
prepare_abx=true


feats_suffix="" #mainly for vad and cmvn. What directly interacts with features
exp_suffix=""

#feats-spec values
vad=false #not in original experiment. 
cmvn=false
deltas=false
deltas_sdc=false # not compatible with deltas

diag_only=false #if true, only train a diag ubm and not a full one. 

lda_dim=19 #NEED TO MAKE IT SIZE OF TEN SET> AUTMOATIZE IT. 
num_gauss=128
ivector_dim=150
test_data=test

abx_dir=../abx/kaldi_exps

. ./cmd.sh
. ./path.sh
. utils/parse_options.sh

set -e # exit on error

#### Kaldi data preparation ####

if [ $stage -eq 0 ] || [ $stage -lt 0 ] && [ "${grad}" == "true" ]; then

    #Explain how get the raw data?
    
    for x in train_english train_xitsonga test_english test_xitsonga; do
        echo "**** Preparing ${x} data ****"
        ./local/data_prep/prepare_xitsonga_english.sh --no_speaker_info ${no_speaker_info} ${raw_data}/lists/${x}.txt ${raw_data}/wavs $data/${x}${feats_suffix}
    done;

    
fi


#### Replication Experiment 6 ####

# Feature Extraction #

if [ $stage -eq 1 ] || [ $stage -lt 1 ] && [ "${grad}" == "true" ]; then


    
    mfcc_conf=conf/mfcc.original.conf

    for x in train_english train_xitsonga test_english test_xitsonga; do
        steps/make_mfcc.sh --mfcc-config ${mfcc_conf} --cmd "${train_cmd}" --nj ${nj} \
                           ${data}/${x}${feats_suffix}
        #creating fake cmvn

        if [ "${cmvn}" == "true" ]; then
            steps/compute_cmvn_stats.sh ${data}/${x}${feats_suffix}
        fi

        if [ "${vad}" == "true" ]; then
            steps/compute_vad_decision.sh --cmd "$train_cmd" ${data}/${x}${feats_suffix}
        # else
        #     echo "Creating a fake vad file"
        #     #create a fake vad.scp filled with 1s. 
        #     local/utils/create_nil_scp.py --filler 1 ${data}/${x}/feats.scp ${data}/${x}/vad
        #     touch ${data}/${x}/.fake_vad
        fi
        
        utils/validate_data_dir.sh --no-text ${data}/${x}${feats_suffix}

    done
    # If wanna add pitch for later experiments - have to run the make mfcc pitch script here instead. 
    # Same if wanna add CMN. Doesn't really make sense here anyway. .
fi 


if [ ! -d ${data}/train_bilingual${feats_suffix} ]; then
    #combine data dir to create train_bilingual - do itafter feature extraction so that don't have features twice.
    utils/combine_data.sh ${data}/train_bilingual_full${feats_suffix} ${data}/train_english${feats_suffix} ${data}/train_xitsonga${feats_suffix}
    #subset data dir to keep good size. 
    utils/subset_data_dir.sh --utt-list ../../data/xitsonga_english/lists/train_bilingual.txt ${data}/train_bilingual_full${feats_suffix} ${data}/train_bilingual${feats_suffix}
    utils/fix_data_dir.sh ${data}/train_bilingual${feats_suffix}
    utils/validate_data_dir.sh --no-text ${data}/train_bilingual${feats_suffix}
    
fi


if [ ! -d ${data}/test${feats_suffix} ]; then
    #combine data dir to create train_bilingual - do itafter feature extraction so that don't have features twice.
    utils/combine_data.sh ${data}/test${feats_suffix} ${data}/test_english${feats_suffix} ${data}/test_xitsonga${feats_suffix}
    utils/fix_data_dir.sh ${data}/test${feats_suffix}
    utils/validate_data_dir.sh --no-text ${data}/test${feats_suffix}
    
fi

#Need VAD here? Might be required by next steps. 

# UBM Training #

if [ $stage -eq 2 ] || [ $stage -lt 2 ] && [ "${grad}" == "true" ]; then

    for train in train_english train_xitsonga train_bilingual; do 
        
        echo "*** Training diag UBM with $train dataset ***"
        local/lid/train_diag_ubm.sh --cmd "$train_cmd --mem 20G" \
                                    --nj 30 --num-threads 8 \
                                    --parallel_opts "" \
                                    --cmvn ${cmvn} --vad ${vad} \
                                    --deltas ${deltas} --deltas_sdc ${deltas_sdc} \
                                    ${data}/${train}${feats_suffix} ${num_gauss} \
                                    exp/ubm${exp_suffix}/diag_ubm_${num_gauss}_${train}${feats_suffix}

        #TODO : use feat_opts to retrieve feat opts for future scripts. 
        printf "vad: $vad \n cmvn: $cmvn \n deltas: $deltas \n deltas_sdc: $deltas_sdc" > exp/ubm${exp_suffix}/diag_ubm_${num_gauss}_${train}${feats_suffix}/feat_opts
    done
fi
if [ $stage -eq 3 ] || [ $stage -lt 3 ] && [ "${grad}" == "true" ]; then
    
    for train in train_english train_xitsonga train_bilingual; do
        
        if [ "$diag_only" != "true" ]; then

            echo "Training on diagonal ubm only - no full ubm"

            mkdir -p exp/ubm${exp_suffix}/full_ubm_${num_gauss}_${train}${feats_suffix}

            #TODO SLURM IT 
            gmm-global-to-fgmm exp/ubm${exp_suffix}/diag_ubm_${num_gauss}_${train}${feats_suffix}/final.dubm exp/ubm${exp_suffix}/full_ubm_${num_gauss}_${train}${feats_suffix}/final.ubm

        else
            
            #Same for full ubm - need to remove the cmn 
            echo "*** Training full UBM with $train dataset ***"
            local/lid/train_full_ubm.sh --nj 30 --cmd "$train_cmd" \
                                        --cmvn ${cmvn} --vad ${vad} \
                                        --deltas ${deltas} --deltas_sdc ${deltas_sdc} \
                                        ${data}/${train}${feats_suffix} \
                                        exp/ubm${exp_suffix}/diag_ubm_${num_gauss}_${train}${feats_suffix} exp/ubm${exp_suffix}/full_ubm_${num_gauss}_${train}${feats_suffix};

            
        fi


        printf "vad: $vad \n cmvn: $cmvn \n deltas: $deltas \n deltas_sdc: $deltas_sdc" > exp/ubm${exp_suffix}/full_ubm_${num_gauss}_${train}${feats_suffix}/feat_opts


    done
fi

if [ $stage -eq 4 ] || [ $stage -lt 4 ] && [ "${grad}" == "true" ]; then


    
    for train in train_english train_xitsonga train_bilingual; do 
        
        
        local/lid/train_ivector_extractor.sh --cmd "$train_cmd --mem 2G" \
                                             --num-iters 5 --num_processes 1 \
                                             --ivector_dim ${ivector_dim} \
                                             --cmvn ${cmvn} --vad ${vad} \
                                             --deltas ${deltas} --deltas_sdc ${deltas_sdc} \
                                             exp/ubm${exp_suffix}/full_ubm_${num_gauss}_${train}${feats_suffix}/final.ubm ${data}/${train}${feats_suffix}  exp/ubm${exp_suffix}/extractor_full_ubm_${num_gauss}_${train}${feats_suffix}
        printf "vad: $vad \n cmvn: $cmvn \n deltas: $deltas \n deltas_sdc: $deltas_sdc" > exp/ubm${exp_suffix}/extractor_full_ubm_${num_gauss}_${train}${feats_suffix}/feat_opts
    done
fi


if [ $stage -eq 5 ] || [ $stage -lt 5 ] && [ "${grad}" == "true" ]; then

   

        for train in train_english train_xitsonga train_bilingual; do
            local/lid/extract_ivectors.sh --cmd "$train_cmd --mem 3G" --nj 20 \
                                          --cmvn ${cmvn} --vad ${vad} \
                                          --deltas ${deltas} --deltas_sdc ${deltas_sdc} \
                                          exp/ubm${exp_suffix}/extractor_full_ubm_${num_gauss}_${train}${feats_suffix} ${data}/${test_data}${feats_suffix} exp/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_data}${feats_suffix};
            printf "vad: $vad \n cmvn: $cmvn \n deltas: $deltas \n deltas_sdc: $deltas_sdc" > exp/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_data}${feats_suffix}/feat_opts;
            
        done

fi

# -------------------------------------------------------------------------



#create ivectors.item
if [ ! -f ${data}/${test_data}${feats_suffix}/ivectors.item ]; then
    echo "** Creating ${data}/${test_data}${feats_suffix}/ivectors.item **"
    python local/utils/utt2lang_to_item.py --ivector_dim ${ivector_dim} ${data}/${test_data}${feats_suffix}
fi




if [ $stage -eq 6 ] || [ $stage -lt 6 ] && [ "${grad}" == "true" ] && [ "$prepare_abx" == "true" ]; then
    #TODO make it compatible with slurm and make it check if data already exist.

    for train in train_english train_xitsonga train_bilingual; do
        echo "** Computing ivectors_to_h5f files for exp/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_data}${feats_suffix}/** "

        ivec_dir=exp/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_data}${feats_suffix}
            
        
        rm -f ${ivec_dir}/ivectors.h5f
        sbatch --mem=5G -n 5 local/utils/ivectors_to_h5f.py ${ivec_dir}/ivector.scp ${ivec_dir}
        while [ ! -f ${ivec_dir}/ivectors.h5f ]; do sleep 2; done

    done


    echo "** Creating abx directories in ${abx_dir} **"
    #create abx directories
    for train in train_english train_xitsonga train_bilingual; do

        path_to_h5f=$(readlink -f exp/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_data}${feats_suffix}/ivectors.h5f)
        path_to_item=$(readlink -f ${data}/${test_data}${feats_suffix}/ivectors.item)
        tgt_abx_dir=${abx_dir}${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_data}${feats_suffix}

        rm -f ${tgt_abx_dir}/ivectors.*
        mkdir -p ${tgt_abx_dir}
        ln -s ${path_to_h5f} ${tgt_abx_dir}/. #CREATE ABX DIR ETC!!!!
        ln -s ${path_to_item} ${tgt_abx_dir}/.
    done;
        
fi


# COMPUTE LDA AND ADD TO ABX. 
if [ $stage -eq 7 ] || [ $stage -lt 7 ] && [ "${grad}" == "true" ]; then


    for train in train_english train_xitsonga train_bilingual; do
        echo "Computing lda for exp/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_data}${feats_suffix}"

        # ivec_train_dir=exp/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${train}${feats_suffix}

        # #If ivectors not a`lready extracted for train
        # if [ ! -f ${ivec_train_dir}/ivector.scp ]; then
        #     local/lid/extract_ivectors.sh --cmd "$train_cmd --mem 3G" --nj 20 \
        #                                   --cmvn ${cmvn} --vad ${vad} \
        #                                   --deltas ${deltas} --deltas_sdc ${deltas_sdc} \
        #                                   exp/ubm${exp_suffix}/extractor_full_ubm_${num_gauss}_${train}${feats_suffix} ${data}/${train}${feats_suffix} ${ivec_train_dir};
        #     printf "vad: $vad \n cmvn: $cmvn \n deltas: $deltas \n deltas_sdc: $deltas_sdc" > ${ivec_train_dir}/feat_opts;
        # fi

        # logdir_train=${ivec_train_dir}/log


 
        ivec_dir=exp/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_data}${feats_suffix}
        logdir=${ivec_dir}/log

        
        if [ ! -f ${ivec_dir}/lda.mat ]; then 
            "$train_cmd"  ${logdir}/compute-lda.log \
                          ivector-compute-lda --dim=$lda_dim scp:${ivec_dir}/ivector.scp ark:${data}/${test_data}${feats_suffix}/utt2spk ${ivec_dir}/lda.mat
        fi


        if [ ! -f ${ivec_dir}/lda_ivector.scp ]; then 
            
            "$train_cmd"  ${logdir}/transform-ivectors.log \
                          ivector-transform ${ivec_dir}/lda.mat scp:${ivec_dir}/ivector.scp ark,scp:${ivec_dir}/lda_ivector.ark,${ivec_dir}/lda_ivector.scp;
        fi
    done




    if [ "$prepare_abx" == "true" ]; then

        for train in train_english train_xitsonga train_bilingual; do
            echo "** Computing ivectors_to_h5f files for exp/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_data}${feats_suffix}/** "

            ivec_dir=exp/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_data}${feats_suffix}
            
            rm -f ${ivec_dir}/lda_ivectors.h5f
            sbatch --mem=5G -n 5 local/utils/ivectors_to_h5f.py --output_name lda_ivectors.h5f ${ivec_dir}/lda_ivector.scp ${ivec_dir}
            while [ ! -f ${ivec_dir}/lda_ivectors.h5f ]; do sleep 2; done

        done

        echo "** Creating abx directories in ${abx_dir} **"
        #create abx directories
        for train in train_english train_xitsonga train_bilingual; do

            path_to_h5f=$(readlink -f exp/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_data}${feats_suffix}/lda_ivectors.h5f)
            path_to_item=$(readlink -f ${data}/${test_data}${feats_suffix}/ivectors.item)
            tgt_abx_dir=${abx_dir}${exp_suffix}/lda_ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_data}${feats_suffix}

            rm -f ${tgt_abx_dir}/ivectors.*
            mkdir -p ${tgt_abx_dir}
            ln -s ${path_to_h5f} ${tgt_abx_dir}/ivectors.h5f # change the name to ivectors.h5f because already n lda directory. to keep consistent. 
            ln -s ${path_to_item} ${tgt_abx_dir}/.
        done;
    fi    
    

fi
