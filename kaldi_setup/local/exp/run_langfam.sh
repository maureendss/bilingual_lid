#!/usr/bin/env bash

# File for first steps on IVector Experiments


mfcc_conf=mfcc.original.conf # mfcc configuration file. The "original" one attempts to reproduce the settings in julia's experiments. 
stage=0
grad=true
nj=40
nj_train=10
data=data/emime-controlled #to chnge. Maybe make as complusory option?
raw_data=../../data/emime
raw_data_lists=../../data/emime/lists-controlled
no_speaker_info=false
prepare_abx=true

exp_dir=exp_emime-controlled
abx_dir=../abx/EMIME-controlled

feats_suffix="" #mainly for vad and cmvn. What directly interacts with features
exp_suffix="" #redundant with exp_dir? TODO to change


train_ger="train_mono_eng_native" #all datasets related to eng-ger train sets
train_fin="train_mono_eng_native"

# Also run it with train_eng-ger-mix and train_eng-fin-mix
test_ger=train_bil_1_eng-ger
test_fin=train_bil_1_eng-fin




#feats-spec values
vad=false #not in original experiment. 
cmvn=false
deltas=false
deltas_sdc=true # not compatible with deltas
diag_only=false #if true, only train a diag ubm and not a full one. 

lda_dim_test=
lda_dim_train=
num_gauss=128
ivector_dim=150



#Additional setup
# run_inversed_lda=false
# inv_lda=5


. ./cmd.sh
. ./path.sh
. utils/parse_options.sh

set -e # exit on error


# ----------------------------------------------------------------------
#Stage 0: Kaldi Data Preparation
# ----------------------------------------------------------------------

if [ $stage -eq 0 ] || [ $stage -lt 0 ] && [ "${grad}" == "true" ]; then

    #Explain how get the raw data?
    
    echo "**** Preparing main 'all' data ****"
    ./local/data_prep/prepare_emime.sh --no_speaker_info ${no_speaker_info} ${raw_data}/wavs $data/all${feats_suffix}

fi



# ----------------------------------------------------------------------
#Stage 1 : Features Extraction
# ----------------------------------------------------------------------

if [ $stage -eq 1 ] || [ $stage -lt 1 ] && [ "${grad}" == "true" ]; then


    
    mfcc_conf=conf/mfcc.original.conf

    for x in all; do

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

# ----------------------------------------------------------------------
#Stage 2 : Combining datasets
# ----------------------------------------------------------------------

if [ $stage -eq 2 ] || [ $stage -lt 2 ] && [ "${grad}" == "true" ]; then
datasets_list="${test_ger} ${test_fin} ${train_ger} ${train_fin}"
local/data_prep/combine_sets_emime.sh --utt_lists_dir ${raw_data_lists} --datasets_list "${datasets_list}" ${data}

fi
 

# ----------------------------------------------------------------------
#Stage 3 : Diagonal UBM Training
# ----------------------------------------------------------------------

if [ $stage -eq 3 ] || [ $stage -lt 3 ] && [ "${grad}" == "true" ]; then

    for train in $train_fin $train_ger; do 

        diag_ubm=${exp_dir}/ubm${exp_suffix}/diag_ubm_${num_gauss}_${train}${feats_suffix}
        if [ ! -f ${diag_ubm}/final.dubm ]; then
            echo "*** Training diag UBM with $train dataset ***"
            local/lid/train_diag_ubm.sh --cmd "$train_cmd --mem 20G" \
                                        --nj ${nj_train} --num-threads 8 \
                                        --parallel_opts "" \
                                        --cmvn ${cmvn} --vad ${vad} \
                                        --deltas ${deltas} --deltas_sdc ${deltas_sdc} \
                                        ${data}/${train}${feats_suffix} ${num_gauss} \
                                        ${diag_ubm}

            #TODO : use feat_opts to retrieve feat opts for future scripts. 
            printf "vad: $vad \n cmvn: $cmvn \n deltas: $deltas \n deltas_sdc: $deltas_sdc" > ${diag_ubm}/feat_opts
        else
            echo "*** diag UBM with $train dataset already exists - skipping ***"
        fi
    done
fi



# ----------------------------------------------------------------------
#Stage 4 : Full UBM Training
# ----------------------------------------------------------------------

if [ $stage -eq 4 ] || [ $stage -lt 4 ] && [ "${grad}" == "true" ]; then
    
    for train in $train_fin $train_ger; do 

        diag_ubm=${exp_dir}/ubm${exp_suffix}/diag_ubm_${num_gauss}_${train}${feats_suffix}
        full_ubm=${exp_dir}/ubm${exp_suffix}/full_ubm_${num_gauss}_${train}${feats_suffix}

        if [ ! -f ${full_ubm}/final.ubm ]; then 
            
            if [ "$diag_only" == "true" ]; then

                echo "Training on diagonal ubm only - no full ubm"
                
                mkdir -p ${full_ubm}
                
                "$train_cmd"  ${full_ubm}/log/gmm-to-fgmm.log \
                              gmm-global-to-fgmm ${diag_ubm}/final.dubm ${full_ubm}/final.ubm

            else
                
                #Same for full ubm - need to remove the cmn 
                echo "*** Training full UBM with $train dataset ***"
                local/lid/train_full_ubm.sh --nj ${nj_train} --cmd "$train_cmd" \
                                            --cmvn ${cmvn} --vad ${vad} \
                                            --deltas ${deltas} --deltas_sdc ${deltas_sdc} \
                                            ${data}/${train}${feats_suffix} \
                                            ${diag_ubm} ${full_ubm};

                
            fi


            printf "vad: $vad \n cmvn: $cmvn \n deltas: $deltas \n deltas_sdc: $deltas_sdc" > ${full_ubm}/feat_opts

        else
            echo "${full_ubm}/final.ubm already exists - skipping full UBM training"
        fi
    done
fi


# ----------------------------------------------------------------------
#Stage 5: Training I-Vector Extractor
# ----------------------------------------------------------------------

if [ $stage -eq 5 ] || [ $stage -lt 5 ] && [ "${grad}" == "true" ]; then
    
    for train in $train_fin $train_ger; do 

        full_ubm=${exp_dir}/ubm${exp_suffix}/full_ubm_${num_gauss}_${train}${feats_suffix}
        extractor=${exp_dir}/ubm${exp_suffix}/extractor_full_ubm_${num_gauss}_${train}${feats_suffix}
        
        if [ ! -f ${extractor}/final.ie ]; then
            echo "Training IVector Extractor for train set ${train}"
            
            local/lid/train_ivector_extractor.sh --cmd "$train_cmd --mem 2G" \
                                                 --nj ${nj_train} \
                                                 --num-iters 5 --num_processes 1 \
                                                 --ivector_dim ${ivector_dim} \
                                                 --cmvn ${cmvn} --vad ${vad} \
                                                 --deltas ${deltas} --deltas_sdc ${deltas_sdc} \
                                                 ${full_ubm}/final.ubm ${data}/${train}${feats_suffix}  ${extractor}
            printf "vad: $vad \n cmvn: $cmvn \n deltas: $deltas \n deltas_sdc: $deltas_sdc" > ${extractor}/feat_opts
        else
            echo "${extractor}/final.ie already exists - skipping training ivector extractor for ${train}"
        fi
    done
fi



# ----------------------------------------------------------------------
#Stage 6: Extracting I-Vectors (train and test)
# ----------------------------------------------------------------------

if [ $stage -eq 6 ] || [ $stage -lt 6 ] && [ "${grad}" == "true" ]; then

    #Also extracting train I-Vectors as will be useful when computing LDA. 


    # DO it separatel for german and finnish 
        for train in $train_fin; do

            for iv_type in ${train} ${test_fin}; do 

                ivec_dir=${exp_dir}/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${iv_type}${feats_suffix}

                if [ ! -f ${ivec_dir}/ivector.scp ]; then

                    nj_ivec=$(wc -l ${data}/${iv_type}${feats_suffix}/spk2utt | cut -d' ' -f1)
                    echo NJ VEC = $nj_ivec
                    local/lid/extract_ivectors.sh --cmd "$train_cmd --mem 3G" --nj ${nj_ivec} \
                                                  --cmvn ${cmvn} --vad ${vad} \
                                                  --deltas ${deltas} --deltas_sdc ${deltas_sdc} \
                                                  ${exp_dir}/ubm${exp_suffix}/extractor_full_ubm_${num_gauss}_${train}${feats_suffix} ${data}/${iv_type}${feats_suffix} ${ivec_dir};
                    printf "vad: $vad \n cmvn: $cmvn \n deltas: $deltas \n deltas_sdc: $deltas_sdc" > ${ivec_dir}/feat_opts;
                else
                    echo "Ivectors in ${ivec_dir} already exist - skipping Ivector Extraction"
                fi
            done
        done



        # ---------------------------------------------------------------------
        # Same for train ger
        for train in $train_ger; do

            for iv_type in ${train} ${test_ger}; do 

                ivec_dir=${exp_dir}/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${iv_type}${feats_suffix}

                    nj_ivec=$(wc -l ${data}/${iv_type}${feats_suffix}/spk2utt | cut -d' ' -f1)
                    echo NJ VEC = $nj_ivec
                
                if [ ! -f ${ivec_dir}/ivector.scp ]; then
                    local/lid/extract_ivectors.sh --cmd "$train_cmd --mem 3G" --nj ${nj_ivec} \
                                                  --cmvn ${cmvn} --vad ${vad} \
                                                  --deltas ${deltas} --deltas_sdc ${deltas_sdc} \
                                                  ${exp_dir}/ubm${exp_suffix}/extractor_full_ubm_${num_gauss}_${train}${feats_suffix} ${data}/${iv_type}${feats_suffix} ${ivec_dir};
                    printf "vad: $vad \n cmvn: $cmvn \n deltas: $deltas \n deltas_sdc: $deltas_sdc" > ${ivec_dir}/feat_opts;
                else
                    echo "Ivectors in ${ivec_dir} already exist - skipping Ivector Extraction"
                fi
            done
        done
fi




# ----------------------------------------------------------------------
#Stage 7: Computing LDA (train and test) and Applying LDA (on test)
# ----------------------------------------------------------------------



#CAREFUL : Here LDA is language based.  Will obviously be 2 but in case.

# --- Figuring out LDA dims ---- Careful 
if [ -z "$lda_dim_test_engfin" ]; then
    num_lang_engfin=$(cut -d' ' -f2 ${data}/${test_fin}${feats_suffix}/utt2lang | sort | uniq | wc -l |cut -d' ' -f1)
    lda_dim_test_engfin=$(($num_lang_engfin - 1))
    echo "lda_dim_test_engfin set to ${lda_dim_test_engfin}"
fi

if [ -z "$lda_dim_test_engger" ]; then
    num_lang_engger=$(cut -d' ' -f2 ${data}/${test_ger}${feats_suffix}/utt2lang |sort | uniq | wc -l |cut -d' ' -f1)
    lda_dim_test_engger=$(($num_lang_engger - 1))
    echo "lda_dim_test_engger set to ${lda_dim_test_engger}"
fi





if [ $stage -eq 7 ] || [ $stage -lt 7 ] && [ "${grad}" == "true" ] && [ "$prepare_abx" == "true" ]; then


    # -------------------------------------


    # For all train sets  in train fin
    for train in $train_fin; do

        num_lang_train=$(cut -d' ' -f2 ${data}/${train}${feats_suffix}/utt2lang | sort | uniq | wc -l |cut -d' ' -f1)
        lda_dim_train=$(($num_lang_train - 1))
        
        ivec_test_dir=${exp_dir}/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_fin}${feats_suffix}
        logdir_test=${ivec_test_dir}/log_langlda
    
        # LDA on train and test Ivectors
        for x in ${train} ${test_fin}; do
            lda_train_dir=${exp_dir}/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${x}${feats_suffix}
            logdir_lda=${lda_train_dir}/log_langlda

            if [ "${x}" == "${test_fin}" ]; then lda_dim=${lda_dim_test_engfin}; else lda_dim=${lda_dim_train}; fi

            if [ ! -f ${lda_train_dir}/lda_lang-${lda_dim}.mat ]; then

                echo "Computing lda for ${x} in ${lda_train_dir} with $lda_dim dimensions"
                
                "$train_cmd"  ${logdir_lda}/compute-lda.log \
                              ivector-compute-lda --dim=$lda_dim scp:${lda_train_dir}/ivector.scp ark:${data}/${x}${feats_suffix}/utt2lang ${lda_train_dir}/lda_lang-${lda_dim}.mat
            fi

            if [ "${x}" == "${test_fin}" ]; then lda_filename="lda_lang-${lda_dim}-test_ivector"; else lda_filename="lda_lang-${lda_dim}-train_ivector"; fi
            
            if [ ! -f ${ivec_test_dir}/${lda_filename}.scp ]; then

                "$train_cmd"  ${logdir_test}/${lda_filename}/transform-ivectors-train.log \
                              ivector-transform ${lda_train_dir}/lda_lang-${lda_dim}.mat scp:${ivec_test_dir}/ivector.scp ark,scp:${ivec_test_dir}/${lda_filename}.ark,${ivec_test_dir}/${lda_filename}.scp;
            fi

            if [ ! -f ${lda_train_dir}/${lda_filename}.scp ]; then
                
                "$train_cmd"  ${logdir_lda}/${lda_filename}/transform-ivectors-train-lda.log \
                              ivector-transform ${lda_train_dir}/lda_lang-${lda_dim}.mat scp:${lda_train_dir}/ivector.scp ark,scp:${lda_train_dir}/${lda_filename}.ark,${lda_train_dir}/${lda_filename}.scp;
            fi 
        done
    done



    # DO same for train ger (TODO: Put it in loop)
    for train in $train_ger; do
        num_lang_train=$(cut -d' ' -f2 ${data}/${train}${feats_suffix}/utt2lang | sort | uniq | wc -l |cut -d' ' -f1)
        lda_dim_train=$(($num_lang_train - 1))
                
        
        ivec_test_dir=${exp_dir}/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_ger}${feats_suffix}
        logdir_test=${ivec_test_dir}/log_langlda
    
        # LDA on train and test Ivectors
        for x in ${train} ${test_ger}; do
            lda_train_dir=${exp_dir}/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${x}${feats_suffix}
            logdir_lda=${lda_train_dir}/log_langlda

            if [ "${x}" == "${test_ger}" ]; then lda_dim=${lda_dim_test_engger}; else lda_dim=${lda_dim_train}; fi

            if [ ! -f ${lda_train_dir}/lda_lang-${lda_dim}.mat ]; then

                echo "Computing lda for ${x} in ${lda_train_dir} with $lda_dim dimensions"
                
                "$train_cmd"  ${logdir_lda}/compute-lda.log \
                              ivector-compute-lda --dim=$lda_dim scp:${lda_train_dir}/ivector.scp ark:${data}/${x}${feats_suffix}/utt2lang ${lda_train_dir}/lda-${lda_dim}_lang.mat
            fi

            if [ "${x}" == "${test_ger}" ]; then lda_filename="lda_lang-${lda_dim}-test_ivector"; else lda_filename="lda_lang-${lda_dim}-train_ivector"; fi
            
            if [ ! -f ${ivec_test_dir}/${lda_filename}.scp ]; then

                "$train_cmd"  ${logdir_test}/${lda_filename}/transform-ivectors-train.log \
                              ivector-transform ${lda_train_dir}/lda_lang-${lda_dim}.mat scp:${ivec_test_dir}/ivector.scp ark,scp:${ivec_test_dir}/${lda_filename}.ark,${ivec_test_dir}/${lda_filename}.scp;
            fi
            if [ ! -f ${lda_train_dir}/${lda_filename}.scp ]; then
                
                "$train_cmd"  ${logdir_lda}/${lda_filename}/transform-ivectors-train-lda.log \
                              ivector-transform ${lda_train_dir}/lda_lang-${lda_dim}.mat scp:${lda_train_dir}/ivector.scp ark,scp:${lda_train_dir}/${lda_filename}.ark,${lda_train_dir}/${lda_filename}.scp;
            fi 
        done
    done
  
fi

# ----------------------------------------------------------------------
#Stage 8: Setting up ABX directory for non-LDA I-Vectors AND LDA
# ----------------------------------------------------------------------

if [ $stage -eq 8 ] || [ $stage -lt 8 ] && [ "${grad}" == "true" ] && [ "$prepare_abx" == "true" ]; then


    for train in $train_fin; do

        num_lang_train=$(cut -d' ' -f2 ${data}/${train}${feats_suffix}/utt2lang | sort | uniq | wc -l |cut -d' ' -f1)
        lda_dim_train=$(($num_lang_train - 1))
        
            
        ivec_dir=${exp_dir}/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_fin}${feats_suffix}       

        #create ivectors.item #TODO ADD SLURM
        if [ ! -f ${ivec_dir}/ivectors.item ]; then
            echo "** Creating ${ivec_dir}/ivectors.item **"
            python local/utils/utt2lang_to_item.py --ivector_dim ${ivector_dim} ${data}/${test_fin}${feats_suffix} ${ivec_dir}
        fi
 

        
        for x in ivector lda_lang-${lda_dim_test_engfin}-test_ivector lda_lang-${lda_dim_train}-train_ivector; do #changed name from ivectors to ivector in h5f file

            if [ ! -f ${ivec_dir}/${x}.h5f ]; then
                echo "** Computing ivectors_to_h5f files for ${ivec_dir}/** for ${x}"
                echo " Should be in ${ivec_dir}/${x}.h5f"
                rm -rf ${ivec_dir}/tmp
                rm -f ${ivec_dir}/${x}.h5f
                sbatch --mem=1G -n 5 -o ${ivec_dir}/log/ivec2h5f_${x}.log local/utils/ivectors_to_h5f.py --output_name ${x}.h5f ${ivec_dir}/${x}.scp ${ivec_dir}
                while [ ! -f ${ivec_dir}/${x}.h5f ]; do sleep 0.5; done
            else
                echo "${ivec_dir}/${x}.h5f already exists. Not recreating it"
            fi

            if [ ! -f ${ivec_dir}/${x}.csv ]; then
                echo "** Creating ivectors.csv file for for ${ivec_dir}/** for ${x}"
                sbatch --mem=1G -n 5 -o ${ivec_dir}/log/ivec2csv_${x}.log local/utils/ivectors_to_csv.py --output_name ${x}.csv ${ivec_dir}/${x}.scp ${ivec_dir};
                while [ ! -f ${ivec_dir}/${x}.csv ]; do sleep 0.1; done
            fi
            

            #create abx directories
            path_to_h5f=$(readlink -f ${ivec_dir}/${x}.h5f)
            path_to_item=$(readlink -f ${ivec_dir}/ivectors.item)
            path_to_csv=$(readlink -f ${ivec_dir}/${x}.csv)
            tgt_abx_dir=${abx_dir}${exp_suffix}/${x}_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_fin}${feats_suffix}

            echo "** Creating abx directories in ${tgt_abx_dir} **"
            # rm -f ${tgt_abx_dir}/ivectors.*
            mkdir -p ${tgt_abx_dir}
            
            if [ ! -f ${tgt_abx_dir}/ivectors.h5f ]; then ln -s ${path_to_h5f} ${tgt_abx_dir}/ivectors.h5f; fi
            if [ ! -f ${tgt_abx_dir}/ivectors.item ]; then ln -s ${path_to_item} ${tgt_abx_dir}/. ; fi
            if [ ! -f ${tgt_abx_dir}/ivectors.csv ]; then ln -s  ${path_to_csv} ${tgt_abx_dir}/ivectors.csv; fi;
            
        done;
    done;






    
    for train in $train_ger; do
        num_lang_train=$(cut -d' ' -f2 ${data}/${train}${feats_suffix}/utt2lang | sort | uniq | wc -l |cut -d' ' -f1)
        lda_dim_train=$(($num_lang_train - 1))
                
            
        ivec_dir=${exp_dir}/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_ger}${feats_suffix}       

        #create ivectors.item #TODO ADD SLURM
        if [ ! -f ${ivec_dir}/ivectors.item ]; then
            echo "** Creating ${ivec_dir}/ivectors.item **"
            python local/utils/utt2lang_to_item.py --ivector_dim ${ivector_dim} ${data}/${test_ger}${feats_suffix} ${ivec_dir}
        fi
 

        
        for x in ivector lda_lang-${lda_dim_test_engger}-test_ivector lda_lang-${lda_dim_train}-train_ivector; do #changed name from ivectors to ivector in h5f file

            if [ ! -f ${ivec_dir}/${x}.h5f ]; then
                echo "** Computing ivectors_to_h5f files for ${ivec_dir}/** for ${x}"
                echo " Should be in ${ivec_dir}/${x}.h5f"
                rm -rf ${ivec_dir}/tmp
                rm -f ${ivec_dir}/${x}.h5f
                sbatch --mem=1G -n 5 -o ${ivec_dir}/log/ivec2h5f_${x}.log local/utils/ivectors_to_h5f.py --output_name ${x}.h5f ${ivec_dir}/${x}.scp ${ivec_dir}
                while [ ! -f ${ivec_dir}/${x}.h5f ]; do sleep 0.5; done
            else
                echo "${ivec_dir}/${x}.h5f already exists. Not recreating it"
            fi

            if [ ! -f ${ivec_dir}/${x}.csv ]; then
                echo "** Creating ivectors.csv file for for ${ivec_dir}/** for ${x}"
                sbatch --mem=1G -n 5 -o ${ivec_dir}/log/ivec2csv_${x}.log local/utils/ivectors_to_csv.py --output_name ${x}.csv ${ivec_dir}/${x}.scp ${ivec_dir};
                while [ ! -f ${ivec_dir}/${x}.csv ]; do sleep 0.1; done
            fi
            

            #create abx directories
            path_to_h5f=$(readlink -f ${ivec_dir}/${x}.h5f)
            path_to_item=$(readlink -f ${ivec_dir}/ivectors.item)
            path_to_csv=$(readlink -f ${ivec_dir}/${x}.csv)
            tgt_abx_dir=${abx_dir}${exp_suffix}/${x}_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_ger}${feats_suffix}

            echo "** Creating abx directories in ${tgt_abx_dir} **"
            # rm -f ${tgt_abx_dir}/ivectors.*
             mkdir -p ${tgt_abx_dir}
            
            if [ ! -f ${tgt_abx_dir}/ivectors.h5f ]; then ln -s ${path_to_h5f} ${tgt_abx_dir}/ivectors.h5f; fi
            if [ ! -f ${tgt_abx_dir}/ivectors.item ]; then ln -s ${path_to_item} ${tgt_abx_dir}/. ; fi
            if [ ! -f ${tgt_abx_dir}/ivectors.csv ]; then ln -s  ${path_to_csv} ${tgt_abx_dir}/ivectors.csv ; fi
        done;
    done;
        
fi


if [ $stage -eq 10 ] || [ $stage -lt 10 ] && [ "${grad}" == "true" ]; then
    echo "Running orthogonal complement of LDA experiments"
    ./local/exp/run_langfam_orthogonal_complement.sh --train_ger "$train_ger" --train_fin "$train_fin" --test_ger "$test_ger" --test_fin "$test_fin"
fi
