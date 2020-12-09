#!/bin/bash

set -e # exit on error


#MDE : Estimate LDA on I-Vectors and transform ivectors using this LDA. Either on speaker or on language.

data=data/emime-controlled


exp_dir=exp_emime-controlled

feats_suffix="" #mainly for vad and cmvn. What directly interacts with features
exp_suffix="" #redundant with exp_dir? TODO to change


echo "$0 $@"  # Print the command line for logging

[ -f ./path.sh ] && . ./path.sh; # source the path.
. parse_options.sh || exit 1;


if [ $# != 4 ]; then
  echo "Usage: $0  <type> <estimation_set> <estimation_dir> <transformation_dir>"
  echo " e.g.: $0 spk train_bil_1_eng-ger ivectors/ivectors_128_tr-train_bil_1_eng-fin_ts-train_bil_1_eng-fin ivectors/ivectors_128_tr-train_bil_1_eng-fin_ts-test_eng-fin-bil"
  echo " <type> : spk or lang. #Will determine the size of the LDA. "
  echo " <estimation_set> #name of set used to estimate the ivectors.  "
  echo " <estimation_dir> #name of directory containing the ivectors   "
  echo " <transformation_dir> #name of set to transform"
  echo "Options: "
  echo "  See top of the script"
  exit 1;
fi

type=$1
est_set=$2
est_dir=$3
trans_dir=$4

. ./cmd.sh
. ./path.sh
. utils/parse_options.sh


#Estimate LDA dimensions (# of classes minus 1)

if [ "${type}" == "spk" ]; then
  num_classes=$(wc -l ${data}/"${est_set}""${feats_suffix}"/spk2utt | cut -d' ' -f1)
  classes_file=${data}/"${est_set}""${feats_suffix}"/utt2spk
elif [ "${type}" == "lang" ]; then
  num_classes=$(cut -d' ' -f2 ${data}/"${est_set}""${feats_suffix}"/utt2lang | sort | uniq | wc -l |cut -d' ' -f1)
  classes_file=${data}/"${est_set}""${feats_suffix}"/utt2lang

else
  echo "Type : $type is not supported. Only spk or lang are currently supported."
  exit 1
fi

lda_dim=$((${num_classes} - 1))
lda_filename="lda_${type}_on_${est_set}_ivector"


if [ ! -f "${est_dir}"/lda_lang-${lda_dim}.mat ]; then

  echo "Computing lda for ${trans_dir} in ${est_dir} with $lda_dim dimensions"

  "$train_cmd"  "${est_dir}"/log/lda_"${type}"/compute-lda.log \
    ivector-compute-lda --dim="$lda_dim" scp:"${est_dir}"/ivector.scp ark:"${classes_file}" "${est_dir}"/lda_"${type}"-"${lda_dim}".mat
fi

if [ ! -f "${trans_dir}"/"${lda_filename}".scp ]; then
  "$train_cmd"  "${trans_dir}"/log/lda_"${type}"_on_"${est_set}"/transform-ivectors-train.log \
    ivector-transform "${est_dir}"/lda_"${type}"-"${lda_dim}".mat scp:"${trans_dir}"/ivector.scp \
    ark,scp:"${trans_dir}"/"${lda_filename}".ark,"${trans_dir}"/"${lda_filename}".scp;
fi

echo "Successfully computed lda on ${trans_dir} and applied it to ${est_dir} with $lda_dim dimensions"