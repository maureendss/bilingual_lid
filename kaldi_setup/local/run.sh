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

lda_dim_test= #NEED TO MAKE IT SIZE OF TEN SET> AUTMOATIZE IT. 19. 
lda_dim_train=  ###NUM OF SPEAKERS TO AUTOMATIZE. Not possible cause bigger than number of ivector dimensions. Should be 167 but if not set just put the num of ivector dim. 
num_gauss=128
ivector_dim=150
test_data=test

abx_dir=../abx/kaldi_exps

. ./cmd.sh
. ./path.sh
. utils/parse_options.sh

set -e # exit on error


# ----------------------------------------------------------------------
#Stage 0: Kaldi Data Preparation
# ----------------------------------------------------------------------

if [ $stage -eq 0 ] || [ $stage -lt 0 ] && [ "${grad}" == "true" ]; then

    #Explain how get the raw data?
    
    for x in train_english train_xitsonga test_english test_xitsonga; do
        echo "**** Preparing ${x} data ****"
        ./local/data_prep/prepare_xitsonga_english.sh --no_speaker_info ${no_speaker_info} ${raw_data}/lists/${x}.txt ${raw_data}/wavs $data/${x}${feats_suffix}
    done;    
fi



# ----------------------------------------------------------------------
#Stage 1 : Features Extraction
# ----------------------------------------------------------------------

if [ $stage -eq 1 ] || [ $stage -lt 1 ] && [ "${grad}" == "true" ]; then


    
    mfcc_conf=conf/mfcc.original.conf

    for x in train_english train_xitsonga test_english test_xitsonga; do

        if [ ! -f ${data}/${x}${feats_suffix}/feats.scp ]; then
            
            steps/make_mfcc.sh --mfcc-config ${mfcc_conf} --cmd "${train_cmd}" --nj ${nj} \
                               ${data}/${x}${feats_suffix}
        fi

        if [ "${cmvn}" == "true" ] && [ ! -f ${data}/${x}${feats_suffix}/cmvn.scp ]; then
            steps/compute_cmvn_stats.sh ${data}/${x}${feats_suffix}
        fi

        if [ "${vad}" == "true" ] && [ ! -f ${data}/${x}${feats_suffix}/vad.scp ]; then
            steps/compute_vad_decision.sh --cmd "$train_cmd" ${data}/${x}${feats_suffix}
        fi
        
        utils/validate_data_dir.sh --no-text ${data}/${x}${feats_suffix}

    done
    # If wanna add pitch for later experiments - have to run the make mfcc pitch script here instead. 
    # Same if wanna add CMN. Doesn't really make sense here anyway. .
fi 



# Combining Test and Train datasets if not already done

if [ ! -d ${data}/train_bilingual${feats_suffix} ]; then
    #combine data dir to create train_bilingual - do itafter feature extraction so that don't have features twice.
    utils/combine_data.sh ${data}/train_bilingual_full${feats_suffix} ${data}/train_english${feats_suffix} ${data}/train_xitsonga${feats_suffix}
    #subset data dir to keep good size. 
    utils/subset_data_dir.sh --utt-list ../../data/xitsonga_english/lists/train_bilingual.txt ${data}/train_bilingual_full${feats_suffix} ${data}/train_bilingual${feats_suffix}
    utils/fix_data_dir.sh ${data}/train_bilingual${feats_suffix}
    utils/validate_data_dir.sh --no-text ${data}/train_bilingual${feats_suffix}
    
fi


if [ ! -d ${data}/test${feats_suffix} ]; then
    #combine data dir to create train_bilingual - do it after feature extraction so that don't have features twice.
    utils/combine_data.sh ${data}/test${feats_suffix} ${data}/test_english${feats_suffix} ${data}/test_xitsonga${feats_suffix}
    utils/fix_data_dir.sh ${data}/test${feats_suffix}
    utils/validate_data_dir.sh --no-text ${data}/test${feats_suffix}
    
fi


if [ -z "$lda_dim_test" ]; then
    num_spk=$(wc -l ${data}/test${feats_suffix}/spk2utt | cut -d' ' -f1)
    lda_dim_test=$(($num_spk - 1))
    echo "lda_dim_test set to ${lda_dim_test}"
fi

if [ -z "$lda_dim_train" ]; then #careful assume that all train engligh xitsonga bilingual same num of spk

    if [ "$(wc -l ${data}/train_bilingual${feats_suffix}/spk2utt | cut -d' ' -f 1)" != "$(wc -l ${data}/train_english${feats_suffix}/spk2utt | cut -d' ' -f 1)" ] || [ "$(wc -l ${data}/train_bilingual${feats_suffix}/spk2utt | cut -d' ' -f 1)" != "$(wc -l  ${data}/train_xitsonga${feats_suffix}/spk2utt | cut -d' ' -f 1)" ]; then echo "Can't figure out the number of LDA dimensions on train ivectors as the number of speakers differ in the three train sets. Please set --lda_dim_train yourself --> exiting" && exit 1 ; fi
    
    
    num_spk=$(wc -l ${data}/train_bilingual${feats_suffix}/spk2utt | cut -d' ' -f1)
    lda_dim_train=$(($num_spk - 1))
    if [ "${lda_dim_train}" -gt "${ivector_dim}" ]; then lda_dim_train=${ivector_dim}; fi
    echo "lda_dim_train set to ${lda_dim_train}"
fi
 

# ----------------------------------------------------------------------
#Stage 2 : Diagonal UBM Training
# ----------------------------------------------------------------------

if [ $stage -eq 2 ] || [ $stage -lt 2 ] && [ "${grad}" == "true" ]; then

    for train in train_english train_xitsonga train_bilingual; do 

        diag_ubm=exp/ubm${exp_suffix}/diag_ubm_${num_gauss}_${train}${feats_suffix}
        
        echo "*** Training diag UBM with $train dataset ***"
        local/lid/train_diag_ubm.sh --cmd "$train_cmd --mem 20G" \
                                    --nj 30 --num-threads 8 \
                                    --parallel_opts "" \
                                    --cmvn ${cmvn} --vad ${vad} \
                                    --deltas ${deltas} --deltas_sdc ${deltas_sdc} \
                                    ${data}/${train}${feats_suffix} ${num_gauss} \
                                    ${diag_ubm}

        #TODO : use feat_opts to retrieve feat opts for future scripts. 
        printf "vad: $vad \n cmvn: $cmvn \n deltas: $deltas \n deltas_sdc: $deltas_sdc" > ${diag_ubm}/feat_opts
    done
fi



# ----------------------------------------------------------------------
#Stage 3 : Full UBM Training
# ----------------------------------------------------------------------

if [ $stage -eq 3 ] || [ $stage -lt 3 ] && [ "${grad}" == "true" ]; then
    
    for train in train_english train_xitsonga train_bilingual; do

        diag_ubm=exp/ubm${exp_suffix}/diag_ubm_${num_gauss}_${train}${feats_suffix}
        full_ubm=exp/ubm${exp_suffix}/full_ubm_${num_gauss}_${train}${feats_suffix}
        
        if [ "$diag_only" == "true" ]; then

            echo "Training on diagonal ubm only - no full ubm"
    
            mkdir -p ${full_ubm}
            
            "$train_cmd"  ${full_ubm}/log/gmm-to-fgmm.log \
                          gmm-global-to-fgmm ${diag_ubm}/final.dubm ${full_ubm}/final.ubm

        else
            
            #Same for full ubm - need to remove the cmn 
            echo "*** Training full UBM with $train dataset ***"
            local/lid/train_full_ubm.sh --nj 30 --cmd "$train_cmd" \
                                        --cmvn ${cmvn} --vad ${vad} \
                                        --deltas ${deltas} --deltas_sdc ${deltas_sdc} \
                                        ${data}/${train}${feats_suffix} \
                                        ${diag_ubm} ${full_ubm};

            
        fi


        printf "vad: $vad \n cmvn: $cmvn \n deltas: $deltas \n deltas_sdc: $deltas_sdc" > ${full_ubm}/feat_opts


    done
fi


# ----------------------------------------------------------------------
#Stage 4: Training I-Vector Extractor
# ----------------------------------------------------------------------

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



# ----------------------------------------------------------------------
#Stage 5: Extracting I-Vectors (train and test)
# ----------------------------------------------------------------------

if [ $stage -eq 5 ] || [ $stage -lt 5 ] && [ "${grad}" == "true" ]; then

    #Also extracting train I-Vectors as will be useful when computing LDA. 

        for train in train_english train_xitsonga train_bilingual; do

            for iv_type in ${train} ${test_data}; do 

                ivec_dir=exp/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${iv_type}${feats_suffix}

                if [ ! -f ${ivec_dir}/ivector.scp ]; then
                    local/lid/extract_ivectors.sh --cmd "$train_cmd --mem 3G" --nj 20 \
                                                  --cmvn ${cmvn} --vad ${vad} \
                                                  --deltas ${deltas} --deltas_sdc ${deltas_sdc} \
                                                  exp/ubm${exp_suffix}/extractor_full_ubm_${num_gauss}_${train}${feats_suffix} ${data}/${iv_type}${feats_suffix} ${ivec_dir};
                    printf "vad: $vad \n cmvn: $cmvn \n deltas: $deltas \n deltas_sdc: $deltas_sdc" > ${ivec_dir}/feat_opts;
                else
                    echo "Ivectors in ${ivec_dir} already exist - skipping Ivector Extraction"
                fi
            done
            
        done
fi


# ----------------------------------------------------------------------
#Stage 6: Computing LDA (train and test) and Applying LDA (on test)
# ----------------------------------------------------------------------

if [ $stage -eq 6 ] || [ $stage -lt 6 ] && [ "${grad}" == "true" ] && [ "$prepare_abx" == "true" ]; then

    # For all train sets
    for train in train_english train_xitsonga train_bilingual; do


        
        ivec_test_dir=exp/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_data}${feats_suffix}
        logdir_test=${ivec_test_dir}/log


  
        
        # LDA on train and test Ivectors
        for x in ${train} ${test_data}; do
            lda_train_dir=exp/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${x}${feats_suffix}
            logdir_lda=${lda_train_dir}/log

            if [ "${x}" == "${test_data}" ]; then lda_dim=${lda_dim_test}; else lda_dim=${lda_dim_train}; fi

            if [ ! -f ${lda_train_dir}/lda-${lda_dim}.mat ]; then

                echo "Computing lda for ${x} in ${lda_train_dir} with $lda_dim dimensions"
                
                # AUTOMATIZE FINDING LDA DIM (just wc spk2utt)
                "$train_cmd"  ${logdir_lda}/compute-lda.log \
                              ivector-compute-lda --dim=$lda_dim scp:${lda_train_dir}/ivector.scp ark:${data}/${x}${feats_suffix}/utt2spk ${lda_train_dir}/lda-${lda_dim}.mat
            fi

            if [ "${x}" == "${test_data}" ]; then lda_filename="lda-${lda_dim}-test_ivector"; else lda_filename="lda-${lda_dim}-train_ivector"; fi
            
            if [ ! -f ${ivec_test_dir}/${lda_filename}.scp ]; then

                "$train_cmd"  ${logdir_test}/${lda_filename}/transform-ivectors-train.log \
                              ivector-transform ${lda_train_dir}/lda-${lda_dim}.mat scp:${ivec_test_dir}/ivector.scp ark,scp:${ivec_test_dir}/${lda_filename}.ark,${ivec_test_dir}/${lda_filename}.scp;
           fi
        done
    done
fi


# ----------------------------------------------------------------------
#Stage 7: Setting up ABX directory for non-LDA I-Vectors AND LDA
# ----------------------------------------------------------------------

if [ $stage -eq 7 ] || [ $stage -lt 7 ] && [ "${grad}" == "true" ] && [ "$prepare_abx" == "true" ]; then


    for train in train_english train_xitsonga train_bilingual; do

            
        ivec_dir=exp/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_data}${feats_suffix}       

        #create ivectors.item #TODO ADD SLURM
        if [ ! -f ${ivec_dir}/ivectors.item ]; then
            echo "** Creating ${ivec_dir}/ivectors.item **"
            python local/utils/utt2lang_to_item.py --ivector_dim ${ivector_dim} ${data}/${test_data}${feats_suffix} ${ivec_dir}
        fi
 

        
        for x in ivector lda-${lda_dim_test}-test_ivector lda-${lda_dim_train}-train_ivector; do #changed name from ivectors to ivector in h5f file

            if [ ! -f ${ivec_dir}/${x}.h5f ]; then
                echo "** Computing ivectors_to_h5f files for ${ivec_dir}/** for ${x}"
                echo " Should be in ${ivec_dir}/${x}.h5f"
                rm -rf ${ivec_dir}/tmp
                rm -f ${ivec_dir}/${x}.h5f
                sbatch --mem=1G -n 5 local/utils/ivectors_to_h5f.py --output_name ${x}.h5f ${ivec_dir}/${x}.scp ${ivec_dir}
                while [ ! -f ${ivec_dir}/${x}.h5f ]; do sleep 0.5; done
            else
                echo "${ivec_dir}/${x}.h5f already exists. Not recreating it"
            fi

            if [ ! -f ${ivec_dir}/${x}.csv ]; then
                echo "** Creating ivectors.csv file for for ${ivec_dir}/** for ${x}"
                sbatch --mem=1G -n 5 local/utils/ivectors_to_csv.py --output_name ${x}.csv ${ivec_dir}/${x}.scp ${ivec_dir};
                while [ ! -f ${ivec_dir}/${x}.csv ]; do sleep 0.1; done 
            fi

            #create abx directories
            path_to_h5f=$(readlink -f ${ivec_dir}/${x}.h5f)
            path_to_item=$(readlink -f ${ivec_dir}/ivectors.item)
            path_to_csv=$(readlink -f ${ivec_dir}/${x}.csv)
            tgt_abx_dir=${abx_dir}${exp_suffix}/${x}_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_data}${feats_suffix}

            echo "** Creating abx directories in ${tgt_abx_dir} **"
            # rm -f ${tgt_abx_dir}/ivectors.*
            mkdir -p ${tgt_abx_dir}
            if [ ! -f ${tgt_abx_dir}/ivectors.h5f ]; then ln -s ${path_to_h5f} ${tgt_abx_dir}/ivectors.h5f; fi
            if [ ! -f ${tgt_abx_dir}/ivectors.item ]; then ln -s ${path_to_item} ${tgt_abx_dir}/. ; fi
            if [ ! -f ${tgt_abx_dir}/ivectors.csv ]; then ln -s  ${path_to_csv} ${tgt_abx_dir}/ivectors.csv ; fi
            
        done;
    done;
        
fi


# # ----------------------------------------------------------------------
# #Stage 8: Apply MDS and Save figure
# # ----------------------------------------------------------------------

## Data analysis
if [ $stage -eq 8 ] || [ $stage -lt 8 ] && [ "${grad}" == "true" ]; then
    
    for train in train_english train_xitsonga train_bilingual; do

        echo "Creating MDS representations for ${train}"
        # extension=pdf
         extension=svg
        #extension=png
        #TODO: carfeul test ivectors here. Would probably have to do on the test one but lda trained on train
        tgt_dir=exp/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_data}${feats_suffix};
        test_utt2lang=${data}/${test_data}${feats_suffix}/utt2lang;


        if [ ! -f ${tgt_dir}/ivector-mds.${extension} ]; then
            sbatch --mem=1G -n 1 local/utils/analysis/estimated-mds_oldversion.py ${tgt_dir}/ivector.scp ${test_utt2lang} ${tgt_dir}/ivector-mds.${extension};
        fi

        if [ ! -f ${tgt_dir}/lda-${lda_dim_test}-test_ivector-mds.${extension} ]; then
            sbatch --mem=1G -n 1 local/utils/analysis/estimated-mds_oldversion.py ${tgt_dir}/lda-${lda_dim_test}-test_ivector.scp ${test_utt2lang} ${tgt_dir}/lda-${lda_dim_test}-test_ivector-mds.${extension};
        fi


        if [ ! -f ${tgt_dir}/lda-${lda_dim_train}-train_ivector-mds.${extension} ]; then
            sbatch --mem=1G -n 1 local/utils/analysis/estimated-mds_oldversion.py ${tgt_dir}/lda-${lda_dim_train}-train_ivector.scp ${test_utt2lang} ${tgt_dir}/lda-${lda_dim_train}-train_ivector-mds.${extension};
        fi

        
    done;
fi
