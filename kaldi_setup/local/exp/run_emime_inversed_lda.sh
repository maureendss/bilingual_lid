#!/usr/bin/env bash

# File for first steps on IVector Experiments

inversed_lda_dim=5

stage=0
grad=true
nj=40
nj_train=10
data=data/emime #to chnge. Maybe make as complusory option?
raw_data=../../data/emime
raw_data_lists=../../data/emime/lists
no_speaker_info=false
prepare_abx=true
exp_dir=exp_emime

feats_suffix="" #mainly for vad and cmvn. What directly interacts with features
exp_suffix="" #redundant with exp_dir? TODO to change

train_ger="train_bil_eng-ger train_mix_eng-ger train_mono_eng_native train_mono_eng train_mono_ger train_mix_spkmatch_eng-ger" #all datasets related to eng-ger train sets
train_fin="train_bil_eng-fin train_mix_eng-fin train_mono_eng_native train_mono_eng train_mono_fin train_mix_spkmatch_eng-fin"



# TODO : NEED TO BE ABLE TO TRY ALL TEST SETS IN ONCE
test_ger=test_eng-ger-bil
test_fin=test_eng-fin-bil
# test_ger="test_eng-ger-mono test_eng-ger-bil test_eng-ger-mixed"
# test_fin="test_eng-fin-mono test_eng-fin-bil test_eng-fin-mixed"



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

abx_dir=../abx/kaldi_exps_EMIME

. ./cmd.sh
. ./path.sh
. utils/parse_options.sh

set -e # exit on error


# --- Figuring out LDA dims ---- Careful 
if [ -z "$lda_dim_test_engfin" ]; then
    num_spk_engfin=$(wc -l ${data}/${test_fin}${feats_suffix}/spk2utt | cut -d' ' -f1)
    lda_dim_test_engfin=$(($num_spk_engfin - 1))
    echo "lda_dim_test_engfin set to ${lda_dim_test_engfin}"
fi

if [ -z "$lda_dim_test_engger" ]; then
    num_spk_engger=$(wc -l ${data}/${test_ger}${feats_suffix}/spk2utt | cut -d' ' -f1)
    lda_dim_test_engger=$(($num_spk_engger - 1))
    echo "lda_dim_test_engger set to ${lda_dim_test_engger}"
fi





if [ $stage -eq 1 ] || [ $stage -lt 1 ] && [ "${grad}" == "true" ] && [ "$prepare_abx" == "true" ]; then


    # -------------------------------------


    # For all train sets  in train fin
    for train in $train_fin; do

        num_spk_train=$(wc -l ${data}/${train}${feats_suffix}/spk2utt | cut -d' ' -f1)
        lda_dim_train=$(($num_spk_train - 1))
        
        ivec_test_dir=${exp_dir}/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_fin}${feats_suffix}
        logdir_test=${ivec_test_dir}/log
    
        # LDA on train and test Ivectors
        for x in ${train} ${test_fin}; do
            lda_train_dir=${exp_dir}/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${x}${feats_suffix}
            logdir_lda=${lda_train_dir}/log

            
            if [ "${x}" == "${test_fin}" ]; then lda_dim=${lda_dim_test_engfin}; else lda_dim=${lda_dim_train}; fi

            orig_lda=${lda_train_dir}/lda-${lda_dim}.mat
            inv_lda=${lda_train_dir}/inversed-${inversed_lda_dim}_lda-${lda_dim}.mat
            
            
            if [ ! -f ${inv_lda} ] && [ ${inversed_lda_dim} -lt ${lda_dim} ]; then

                echo "Computing inversed lda on ${lda_train_dir}/lda-${lda_dim}.mat using ${inversed_lda_dim} dimensions"
                
                python local/lda/get_nlast_lda_dims.py --tgt_dim ${inversed_lda_dim} ${orig_lda} ${inv_lda}
                
            fi

            if [ "${x}" == "${test_fin}" ]; then inv_lda_filename="inversed-${inversed_lda_dim}_lda-${lda_dim}-test_ivector"; else inv_lda_filename="inversed-${inversed_lda_dim}_lda-${lda_dim}-train_ivector"; fi
            
            if [ ! -f ${ivec_test_dir}/${inv_lda_filename}.scp ] && [ ${inversed_lda_dim} -lt ${lda_dim} ]; then

                "$train_cmd"  ${logdir_test}/${inv_lda_filename}/transform-ivectors-train_inversed-lda.log \
                              ivector-transform ${inv_lda} scp:${ivec_test_dir}/ivector.scp ark,scp:${ivec_test_dir}/${inv_lda_filename}.ark,${ivec_test_dir}/${inv_lda_filename}.scp;
           fi
        done
    done

    # For all train sets  in train ger
    for train in $train_ger; do

        num_spk_train=$(wc -l ${data}/${train}${feats_suffix}/spk2utt | cut -d' ' -f1)
        lda_dim_train=$(($num_spk_train - 1))
        
        ivec_test_dir=${exp_dir}/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_ger}${feats_suffix}
        logdir_test=${ivec_test_dir}/log
    
        # LDA on train and test Ivectors
        for x in ${train} ${test_ger}; do
            lda_train_dir=${exp_dir}/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${x}${feats_suffix}
            logdir_lda=${lda_train_dir}/log

            
            if [ "${x}" == "${test_ger}" ]; then lda_dim=${lda_dim_test_engger}; else lda_dim=${lda_dim_train}; fi

            orig_lda=${lda_train_dir}/lda-${lda_dim}.mat
            inv_lda=${lda_train_dir}/inversed-${inversed_lda_dim}_lda-${lda_dim}.mat
            
            
            if [ ! -f ${inv_lda} ] && [ ${inversed_lda_dim} -lt ${lda_dim} ]; then

                echo "Computing inversed lda on ${lda_train_dir}/lda-${lda_dim}.mat using ${inversed_lda_dim} dimensions"
                
                python local/lda/get_nlast_lda_dims.py --tgt_dim ${inversed_lda_dim} ${orig_lda} ${inv_lda}
                
            fi

            if [ "${x}" == "${test_ger}" ]; then inv_lda_filename="inversed-${inversed_lda_dim}_lda-${lda_dim}-test_ivector"; else inv_lda_filename="inversed-${inversed_lda_dim}_lda-${lda_dim}-train_ivector"; fi
            
            if [ ! -f ${ivec_test_dir}/${inv_lda_filename}.scp ] && [ ${inversed_lda_dim} -lt ${lda_dim} ]; then

                "$train_cmd"  ${logdir_test}/${inv_lda_filename}/transform-ivectors-train_inversed-lda.log \
                              ivector-transform ${inv_lda} scp:${ivec_test_dir}/ivector.scp ark,scp:${ivec_test_dir}/${inv_lda_filename}.ark,${ivec_test_dir}/${inv_lda_filename}.scp;
           fi
        done
    done
    
fi


# ----------------------------------------------------------------------
#Stage 8: Setting up ABX directory for inversed LDA
# ----------------------------------------------------------------------

if [ $stage -eq 8 ] || [ $stage -lt 8 ] && [ "${grad}" == "true" ] && [ "$prepare_abx" == "true" ]; then


    for train in $train_fin; do
        num_spk_train=$(wc -l ${data}/${train}${feats_suffix}/spk2utt | cut -d' ' -f1)
        lda_dim_train=$(($num_spk_train - 1))
        
        
        ivec_dir=${exp_dir}/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_fin}${feats_suffix}       

        # Should already have been done
        # #create ivectors.item #TODO ADD SLURM
        # if [ ! -f ${ivec_dir}/ivectors.item ]; then
        #     echo "** Creating ${ivec_dir}/ivectors.item **"
        #     python local/utils/utt2lang_to_item.py --ivector_dim ${ivector_dim} ${data}/${test_fin}${feats_suffix} ${ivec_dir}
        # fi
        

        for x in inversed-${inversed_lda_dim}_lda-${lda_dim_test_engfin}-test_ivector inversed-${inversed_lda_dim}_lda-${lda_dim_train}-train_ivector; do

            #only if exists
            if [ -f ${ivec_dir}/${x}.scp ]; then 

                
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
            fi
        done;
    done;






    
    for train in $train_ger; do
        num_spk_train=$(wc -l ${data}/${train}${feats_suffix}/spk2utt | cut -d' ' -f1)
        lda_dim_train=$(($num_spk_train - 1))
        
        
        ivec_dir=${exp_dir}/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_ger}${feats_suffix}       

        # #create ivectors.item #TODO ADD SLURM
        # if [ ! -f ${ivec_dir}/ivectors.item ]; then
        #     echo "** Creating ${ivec_dir}/ivectors.item **"
        #     python local/utils/utt2lang_to_item.py --ivector_dim ${ivector_dim} ${data}/${test_ger}${feats_suffix} ${ivec_dir}
        # fi
        

        

        for x in inversed-${inversed_lda_dim}_lda-${lda_dim_test_engger}-test_ivector inversed-${inversed_lda_dim}_lda-${lda_dim_train}-train_ivector; do
            if [ -f ${ivec_dir}/${x}.scp ]; then 
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
            fi
        done;
    done;
    
fi


# # ----------------------------------------------------------------------
# #Stage 9: Apply MDS and Save figure
# # ----------------------------------------------------------------------

## Data analysis
if [ $stage -eq 9 ] || [ $stage -lt 9 ] && [ "${grad}" == "true" ]; then
    # TODO : FIX MDS GRAPH FOR NON GENDER
    for train in ${train_fin}; do

        num_spk_train=$(wc -l ${data}/${train}${feats_suffix}/spk2utt | cut -d' ' -f1)
        lda_dim_train=$(($num_spk_train - 1))
        

        echo "Creating MDS representations for ${train}"
        # extension=pdf
        extension=svg
        #extension=png
        #TODO: carfeul test ivectors here. Would probably have to do on the test one but lda trained on train
        tgt_dir=${exp_dir}/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_fin}${feats_suffix};
        test_utt2lang=${data}/${test_fin}${feats_suffix}/utt2lang;


        if [ ${inversed_lda_dim} -lt ${lda_dim_test_engfin} ] && [ ! -f ${tgt_dir}/inversed-${inversed_lda_dim}_lda-${lda_dim_test_engfin}-test_ivector-mds.${extension} ]; then
            sbatch --mem=5G -n 1 -o ${tgt_dir}/log/inversed-${inversed_lda_dim}_lda-${lda_dim_test_engfin}-test_ivector-mds.log local/utils/analysis/estimated-mds_oldversion.py ${tgt_dir}/inversed-${inversed_lda_dim}_lda-${lda_dim_test_engger}-test_ivector.scp ${test_utt2lang} ${tgt_dir}/inversed-${inversed_lda_dim}_lda-${lda_dim_test_engfin}-test_ivector-mds.${extension};
        fi


        if [ ! -f ${tgt_dir}/inversed-${inversed_lda_dim}_lda-${lda_dim_train}-train_ivector-mds.${extension} ]; then
            sbatch --mem=5G -o ${tgt_dir}/log/inversed-${inversed_lda_dim}_lda-${lda_dim_train}-train_ivector-mds.log -n 1 local/utils/analysis/estimated-mds_oldversion.py ${tgt_dir}/inversed-${inversed_lda_dim}_lda-${lda_dim_train}-train_ivector.scp ${test_utt2lang} ${tgt_dir}/inversed-${inversed_lda_dim}_lda-${lda_dim_train}-train_ivector-mds.${extension};
        fi


        test_utt2gender=${data}/${test_fin}${feats_suffix}/utt2gender;
        # SAME BUT with gender labels

        if [ ${inversed_lda_dim} -lt ${lda_dim_test_engfin} ] && [ ! -f ${tgt_dir}/inversed-${inversed_lda_dim}_lda-${lda_dim_test_engfin}-test_ivector-mds_gender.${extension} ]; then
            sbatch --mem=5G -n 1 -o ${tgt_dir}/log/inversed-${inversed_lda_dim}_lda-${lda_dim_test_engfin}-test_ivector-mds_gender.log local/utils/analysis/estimated-mds.py --utt2gender ${test_utt2gender} ${tgt_dir}/inversed-${inversed_lda_dim}_lda-${lda_dim_test_engfin}-test_ivector.scp ${test_utt2lang} ${tgt_dir}/inversed-${inversed_lda_dim}_lda-${lda_dim_test_engfin}-test_ivector-mds_gender.${extension};
        fi


        if [ ! -f ${tgt_dir}/inversed-${inversed_lda_dim}_lda-${lda_dim_train}-train_ivector-mds_gender.${extension} ]; then
            sbatch --mem=5G -o ${tgt_dir}/log/inversed-${inversed_lda_dim}_lda-${lda_dim_train}-train_ivector-mds_gender.log -n 1 local/utils/analysis/estimated-mds.py --utt2gender ${test_utt2gender} ${tgt_dir}/inversed-${inversed_lda_dim}_lda-${lda_dim_train}-train_ivector.scp ${test_utt2lang} ${tgt_dir}/inversed-${inversed_lda_dim}_lda-${lda_dim_train}-train_ivector-mds_gender.${extension};
        fi


        
    done;



    for train in ${train_ger}; do
        num_spk_train=$(wc -l ${data}/${train}${feats_suffix}/spk2utt | cut -d' ' -f1)
        lda_dim_train=$(($num_spk_train - 1))
        
        echo "Creating MDS representations for ${train}"
        # extension=pdf
        extension=svg
        #extension=png
        #TODO: carfeul test ivectors here. Would probably have to do on the test one but lda trained on train
        tgt_dir=${exp_dir}/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${test_ger}${feats_suffix};
        test_utt2lang=${data}/${test_ger}${feats_suffix}/utt2lang;


        if [ ${inversed_lda_dim} -lt ${lda_dim_test_engfin} ] &&  [ ! -f ${tgt_dir}/inversed-${inversed_lda_dim}_lda-${lda_dim_test_engger}-test_ivector-mds.${extension} ]; then
            sbatch --mem=5G -o ${tgt_dir}/log/inversed-${inversed_lda_dim}_lda-${lda_dim_test_engger}-test_ivector-mds.log -n 1 local/utils/analysis/estimated-mds_oldversion.py ${tgt_dir}/inversed-${inversed_lda_dim}_lda-${lda_dim_test_engger}-test_ivector.scp ${test_utt2lang} ${tgt_dir}/inversed-${inversed_lda_dim}_lda-${lda_dim_test_engger}-test_ivector-mds.${extension};
        fi


        if [ ! -f ${tgt_dir}/inversed-${inversed_lda_dim}_lda-${lda_dim_train}-train_ivector-mds.${extension} ]; then
            sbatch --mem=5G -n 1 -o ${tgt_dir}/log/inversed-${inversed_lda_dim}_lda-${lda_dim_train}-train_ivector-mds.log local/utils/analysis/estimated-mds_oldversion.py ${tgt_dir}/inversed-${inversed_lda_dim}_lda-${lda_dim_train}-train_ivector.scp ${test_utt2lang} ${tgt_dir}/inversed-${inversed_lda_dim}_lda-${lda_dim_train}-train_ivector-mds.${extension};
        fi


        test_utt2gender=${data}/${test_ger}${feats_suffix}/utt2gender;
        # SAME BUT with gender labels

        if [ ${inversed_lda_dim} -lt ${lda_dim_test_engfin} ] && [ ! -f ${tgt_dir}/inversed-${inversed_lda_dim}_lda-${lda_dim_test_engger}-test_ivector-mds_gender.${extension} ]; then
            sbatch --mem=5G -o ${tgt_dir}/log/inversed-${inversed_lda_dim}_lda-${lda_dim_test_engger}-test_ivector-mds_gender.log -n 1 local/utils/analysis/estimated-mds.py --utt2gender ${test_utt2gender} ${tgt_dir}/inversed-${inversed_lda_dim}_lda-${lda_dim_test_engger}-test_ivector.scp ${test_utt2lang} ${tgt_dir}/inversed-${inversed_lda_dim}_lda-${lda_dim_test_engger}-test_ivector-mds_gender.${extension};
        fi


        if [ ! -f ${tgt_dir}/inversed-${inversed_lda_dim}_lda-${lda_dim_train}-train_ivector-mds_gender.${extension} ]; then
            sbatch --mem=5G -o ${tgt_dir}/log/inversed-${inversed_lda_dim}_lda-${lda_dim_train}-train_ivector-mds_gender.log -n 1 local/utils/analysis/estimated-mds.py --utt2gender ${test_utt2gender} ${tgt_dir}/inversed-${inversed_lda_dim}_lda-${lda_dim_train}-train_ivector.scp ${test_utt2lang} ${tgt_dir}/inversed-${inversed_lda_dim}_lda-${lda_dim_train}-train_ivector-mds_gender.${extension};
        fi
        
    done;

fi
