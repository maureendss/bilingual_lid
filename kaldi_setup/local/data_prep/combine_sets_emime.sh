 #!/usr/bin/env bash


datasets_list="train_bil_eng-fin train_bil_eng-ger train_mix_eng-fin train_mix_eng-ger train_mono_eng_native train_mono_eng train_mono_fin train_mono_ger test_eng-fin-mono test_eng-ger-mono test_eng-fin-mixed test_eng-ger-mixed test_eng-ger-bil test_eng-fin-bil"
utt_lists_dir="../../data/emime/lists"
feats_suffix=""
. ./cmd.sh
. ./path.sh
. utils/parse_options.sh



set -e # exit on error

if [ $# != 1 ]; then
   echo "usage: local/combine_sets_emime.sh <data_dir>"
   exit 1;
fi

data=$1


for x in $datasets_list; do

    if [ ! -d $data/${x}${feats_suffix} ]; then
        echo "Creating $data/${x} from $data/all"
        utils/data/subset_data_dir.sh --utt-list ${utt_lists_dir}/${x}.txt ${data}/all${feats_suffix} ${data}/${x}${feats_suffix};
    else
        echo "$data/${x} already exists -passing"

    fi
done
