#!/usr/bin/env bash

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


train_ger="train_bil_1_eng-ger train_mix_1_eng-ger train_mono_eng_native train_mono_eng_gerspk train_mono_ger train_bil_2_eng-ger train_mix_2_eng-ger" #all datasets related to eng-ger train sets
train_fin="train_bil_1_eng-fin train_mix_1_eng-fin train_mono_eng_native train_mono_fin train_mono_eng_finspk train_bil_2_eng-fin train_mix_2_eng-fin"


test_ger=test_eng-ger-bil
test_fin=test_eng-fin-bil




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
            oc_lda=${lda_train_dir}/oc_lda-${lda_dim}.mat
            
            
            if [ ! -f ${oc_lda} ]; then

                echo "Computing oc lda on ${lda_train_dir}/lda-${lda_dim}.mat"
                
                python local/lda/lda_orthogonal_complement.py ${orig_lda} ${oc_lda}
                
            fi

            if [ "${x}" == "${test_fin}" ]; then oc_lda_filename="oc_lda-${lda_dim}-test_ivector"; else oc_lda_filename="oc_lda-${lda_dim}-train_ivector"; fi
            
            if [ ! -f ${ivec_test_dir}/${oc_lda_filename}.scp ]; then

                "$train_cmd"  ${logdir_test}/${oc_lda_filename}/transform-ivectors-train_oc-lda.log \
                              ivector-transform ${oc_lda} scp:${ivec_test_dir}/ivector.scp ark,scp:${ivec_test_dir}/${oc_lda_filename}.ark,${ivec_test_dir}/${oc_lda_filename}.scp;
            fi


            if [ ! -f ${lda_train_dir}/${oc_lda_filename}.scp ]; then
                
                "$train_cmd"  ${logdir_lda}/${oc_lda_filename}/transform-ivectors-train_oc-lda.log \
                              ivector-transform ${oc_lda} scp:${lda_train_dir}/ivector.scp ark,scp:${lda_train_dir}/${oc_lda_filename}.ark,${lda_train_dir}/${oc_lda_filename}.scp;
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

            
            if [ "${x}" == "${test_ger}" ]; then lda_dim=${lda_dim_test_engfin}; else lda_dim=${lda_dim_train}; fi

            orig_lda=${lda_train_dir}/lda-${lda_dim}.mat
            oc_lda=${lda_train_dir}/oc_lda-${lda_dim}.mat
            
            
            if [ ! -f ${oc_lda} ]; then

                echo "Computing oc lda on ${lda_train_dir}/lda-${lda_dim}.mat"
                
                python local/lda/lda_orthogonal_complement.py ${orig_lda} ${oc_lda}
                
            fi

            if [ "${x}" == "${test_ger}" ]; then oc_lda_filename="oc_lda-${lda_dim}-test_ivector"; else oc_lda_filename="oc_lda-${lda_dim}-train_ivector"; fi
            
            if [ ! -f ${ivec_test_dir}/${oc_lda_filename}.scp ]; then

                "$train_cmd"  ${logdir_test}/${oc_lda_filename}/transform-ivectors-train_oc-lda.log \
                              ivector-transform ${oc_lda} scp:${ivec_test_dir}/ivector.scp ark,scp:${ivec_test_dir}/${oc_lda_filename}.ark,${ivec_test_dir}/${oc_lda_filename}.scp;
           fi
            if [ ! -f ${lda_train_dir}/${oc_lda_filename}.scp ]; then
                
                "$train_cmd"  ${logdir_lda}/${oc_lda_filename}/transform-ivectors-train_oc-lda.log \
                              ivector-transform ${oc_lda} scp:${lda_train_dir}/ivector.scp ark,scp:${lda_train_dir}/${oc_lda_filename}.ark,${lda_train_dir}/${oc_lda_filename}.scp;
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
        

        for x in oc_lda-${lda_dim_train}-train_ivector; do

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
        

        

        for x in  oc_lda-${lda_dim_train}-train_ivector; do
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



        if [ ! -f ${tgt_dir}/oc_lda-${lda_dim_train}-train_ivector-mds.${extension} ]; then
            sbatch --mem=5G -o ${tgt_dir}/log/oc_lda-${lda_dim_train}-train_ivector-mds.log -n 1 local/utils/analysis/estimated-mds.py ${tgt_dir}/oc_lda-${lda_dim_train}-train_ivector.scp ${test_utt2lang} ${tgt_dir}/oc_lda-${lda_dim_train}-train_ivector-mds.${extension};
        fi


        test_utt2gender=${data}/${test_fin}${feats_suffix}/utt2gender;
        # SAME BUT with gender labels



        
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


        if [ ! -f ${tgt_dir}/oc_lda-${lda_dim_train}-train_ivector-mds.${extension} ]; then
            sbatch --mem=5G -n 1 -o ${tgt_dir}/log/oc_lda-${lda_dim_train}-train_ivector-mds.log local/utils/analysis/estimated-mds.py ${tgt_dir}/oc_lda-${lda_dim_train}-train_ivector.scp ${test_utt2lang} ${tgt_dir}/oc_lda-${lda_dim_train}-train_ivector-mds.${extension};
        fi


        test_utt2gender=${data}/${test_ger}${feats_suffix}/utt2gender;
        # SAME BUT with gender labels

    done;

fi
