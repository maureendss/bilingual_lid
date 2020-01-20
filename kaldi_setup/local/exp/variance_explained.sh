#!/usr/bin/env bash

# File for first steps on IVector Experiments

abx_dir=../abx/kaldi_exps_EMIME/variance_exp


mfcc_conf=mfcc.original.conf # mfcc configuration file. The "original" one attempts to reproduce the settings in julia's experiments. 
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

train_ger="train_bil_eng-ger train_mix_eng-ger train_mono_eng_native train_mono_eng train_mono_ger" #all datasets related to eng-ger train sets
train_fin="train_bil_eng-fin train_mix_eng-fin train_mono_eng_native train_mono_eng train_mono_fin"



# TODO : NEED TO BE ABLE TO TRY ALL TEST SETS IN ONCE
test_ger=test_eng-ger-mono
test_fin=test_eng-fin-mono
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




#Additional setup
run_inversed_lda=false
inv_lda=5


. ./cmd.sh
. ./path.sh
. utils/parse_options.sh

set -e # exit on error


# ----------------------------------------------------------------------
#Stage 8: Setting up ABX directory for TRAIN SETS
# ----------------------------------------------------------------------

if [ $stage -eq 1 ] || [ $stage -lt 1 ] && [ "${grad}" == "true" ]; then


    for train in $train_fin $train_ger; do
        num_spk_train=$(wc -l ${data}/${train}${feats_suffix}/spk2utt | cut -d' ' -f1)
        
            
        ivec_dir=${exp_dir}/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${train}${feats_suffix}       

        #create ivectors.item #TODO ADD SLURM
        if [ ! -f ${ivec_dir}/ivectors.item ]; then
            echo "** Creating ${ivec_dir}/ivectors.item **"
            python local/utils/utt2lang_to_item.py --ivector_dim ${ivector_dim} ${data}/${train}${feats_suffix} ${ivec_dir}
            echo "DONE COMPUTING ${ivec_dir}/ivectors.item"
        fi
 

        x=ivector

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
        tgt_abx_dir=${abx_dir}${exp_suffix}/${x}_${num_gauss}_tr-${train}${feats_suffix}_ts-${train}${feats_suffix}

        echo "** Creating abx directories in ${tgt_abx_dir} **"
        # rm -f ${tgt_abx_dir}/ivectors.*
        mkdir -p ${tgt_abx_dir}
        
        if [ ! -f ${tgt_abx_dir}/ivectors.h5f ]; then ln -s ${path_to_h5f} ${tgt_abx_dir}/ivectors.h5f; fi
        if [ ! -f ${tgt_abx_dir}/ivectors.item ]; then ln -s ${path_to_item} ${tgt_abx_dir}/. ; fi
        if [ ! -f ${tgt_abx_dir}/ivectors.csv ]; then ln -s  ${path_to_csv} ${tgt_abx_dir}/ivectors.csv; fi;
        

    done;
       
fi


# # ----------------------------------------------------------------------
# #Stage 9: Apply MDS on TRAIN - lang gender and sent
# # ----------------------------------------------------------------------


## Data analysis
if [ $stage -eq 9 ] || [ $stage -lt 9 ] && [ "${grad}" == "true" ]; then
    # TODO : FIX MDS GRAPH FOR NON GENDER
    for train in ${train_fin} ${train_ger}; do

        num_spk_train=$(wc -l ${data}/${train}${feats_suffix}/spk2utt | cut -d' ' -f1)
        

        echo "Creating MDS representations for ${train}"
        # extension=pdf
         extension=svg
        #extension=png
        #TODO: carfeul test ivectors here. Would probably have to do on the test one but lda trained on train
         tgt_dir=${exp_dir}/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${train}${feats_suffix};
         
        test_utt2lang=${data}/${train}${feats_suffix}/utt2lang;
        test_utt2spk=${data}/${train}${feats_suffix}/utt2spk;
        test_utt2sent=${data}/${train}${feats_suffix}/utt2sent;
        

        
        if [ ! -f ${tgt_dir}/ivector-mds_lang.${extension} ]; then
            sbatch --mem=5G -o ${tgt_dir}/log/ivector-mds_lang.log -n 1 local/utils/analysis/estimated-mds_oldversion.py ${tgt_dir}/ivector.scp ${test_utt2lang} ${tgt_dir}/ivector-mds_lang.${extension};
        fi

        if [ ! -f ${tgt_dir}/ivector-mds_spk.${extension} ]; then
            sbatch --mem=5G -o ${tgt_dir}/log/ivector-mds_spk.log -n 1 local/utils/analysis/estimated-mds_oldversion.py ${tgt_dir}/ivector.scp ${test_utt2spk} ${tgt_dir}/ivector-mds_spk.${extension};
        fi

        if [ ! -f ${tgt_dir}/ivector-mds_sent.${extension} ]; then
            sbatch --mem=5G -o ${tgt_dir}/log/ivector-mds_sent.log -n 1 local/utils/analysis/estimated-mds_oldversion.py ${tgt_dir}/ivector.scp ${test_utt2sent} ${tgt_dir}/ivector-mds_sent.${extension};
        fi
        
    done

fi




# # ----------------------------------------------------------------------
# #Stage 10: Apply MDS on TEST - lang gender and sent
# # ----------------------------------------------------------------------

## Data analysis
if [ $stage -eq 10 ] || [ $stage -lt 10 ] && [ "${grad}" == "true" ]; then
    # TODO : FIX MDS GRAPH FOR NON GENDER

    for train in ${train_fin} ; do

        num_spk_train=$(wc -l ${data}/${train}${feats_suffix}/spk2utt | cut -d' ' -f1)
        
        tst=${test_fin}

        # extension=pdf
        extension=svg
        #extension=png
        #TODO: carfeul test ivectors here. Would probably have to do on the test one but lda trained on train
        tgt_dir=${exp_dir}/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${tst}${feats_suffix}; 
        echo "Creating MDS representations for ${tgt_dir}"           
        test_utt2lang=${data}/${tst}${feats_suffix}/utt2lang;
        test_utt2spk=${data}/${tst}${feats_suffix}/utt2spk;
        test_utt2sent=${data}/${tst}${feats_suffix}/utt2sent;
        

        
        if [ ! -f ${tgt_dir}/ivector-mds_lang.${extension} ]; then
            sbatch --mem=5G -o ${tgt_dir}/log/ivector-mds_lang.log -n 1 local/utils/analysis/estimated-mds_oldversion.py ${tgt_dir}/ivector.scp ${test_utt2lang} ${tgt_dir}/ivector-mds_lang.${extension};
        fi

        if [ ! -f ${tgt_dir}/ivector-mds_spk.${extension} ]; then
            sbatch --mem=5G -o ${tgt_dir}/log/ivector-mds_spk.log -n 1 local/utils/analysis/estimated-mds_oldversion.py ${tgt_dir}/ivector.scp ${test_utt2spk} ${tgt_dir}/ivector-mds_spk.${extension};
        fi

        if [ ! -f ${tgt_dir}/ivector-mds_sent.${extension} ]; then
            sbatch --mem=5G -o ${tgt_dir}/log/ivector-mds_sent.log -n 1 local/utils/analysis/estimated-mds_oldversion.py ${tgt_dir}/ivector.scp ${test_utt2sent} ${tgt_dir}/ivector-mds_sent.${extension};
        fi
        
    done



    for train in ${train_ger} ; do

        num_spk_train=$(wc -l ${data}/${train}${feats_suffix}/spk2utt | cut -d' ' -f1)
        

        tst=${test_ger}
        # extension=pdf
        extension=svg
        #extension=png
        #TODO: carfeul test ivectors here. Would probably have to do on the test one but lda trained on train



        tgt_dir=${exp_dir}/ivectors${exp_suffix}/ivectors_${num_gauss}_tr-${train}${feats_suffix}_ts-${tst}${feats_suffix};

        echo "Creating MDS representations for ${tgt_dir}"
        
        test_utt2lang=${data}/${tst}${feats_suffix}/utt2lang;
        test_utt2spk=${data}/${tst}${feats_suffix}/utt2spk;
        test_utt2sent=${data}/${tst}${feats_suffix}/utt2sent;
        

        
        if [ ! -f ${tgt_dir}/ivector-mds_lang.${extension} ]; then
            sbatch --mem=5G -o ${tgt_dir}/log/ivector-mds_lang.log -n 1 local/utils/analysis/estimated-mds_oldversion.py ${tgt_dir}/ivector.scp ${test_utt2lang} ${tgt_dir}/ivector-mds_lang.${extension};
        fi

        if [ ! -f ${tgt_dir}/ivector-mds_spk.${extension} ]; then
            sbatch --mem=5G -o ${tgt_dir}/log/ivector-mds_spk.log -n 1 local/utils/analysis/estimated-mds_oldversion.py ${tgt_dir}/ivector.scp ${test_utt2spk} ${tgt_dir}/ivector-mds_spk.${extension};
        fi

        if [ ! -f ${tgt_dir}/ivector-mds_sent.${extension} ]; then
            sbatch --mem=5G -o ${tgt_dir}/log/ivector-mds_sent.log -n 1 local/utils/analysis/estimated-mds_oldversion.py ${tgt_dir}/ivector.scp ${test_utt2sent} ${tgt_dir}/ivector-mds_sent.${extension};
        fi
        
    done


    
fi
