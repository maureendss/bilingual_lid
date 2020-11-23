 #!/usr/bin/env bash


no_speaker_info=false #We pretend each utterance comes from different speaker. (Just for practicity purposes Probably not needed as we won't generate cmvn but never know. Would have to compare). 



. ./cmd.sh
. ./path.sh
. utils/parse_options.sh



set -e # exit on error

if [ $# != 2 ]; then
   echo "usage: local/prepare_emime.sh <wav_directory> <target_data_dir>"
   echo "e.g.:  local/prepare_xitsonga_english.sh data/xitsonga-english/wavs/ data/english-xitsonga/train_timit"
   exit 1;
fi

wav_directory=$1
tgt_dir=$2

# first put here info on how to get wav list.  


# wav.scp format <utt> <path_wav>
# assumes you have a wav directory with all wavs in it, and with only the utterance name (symlinks to their proper location)

mkdir -p $tgt_dir

if [ ! -f $tgt_dir/wav.scp ]; then
    echo "Creating $tgt_dir/wav.scp"

    for x in $wav_directory/*; do
        utt=$(echo `basename $x .wav`)
        echo "$utt sox ${x} -t wav -r 16000 - |" >> $tgt_dir/wav.scp.tmp;
    done
    sort $tgt_dir/wav.scp.tmp > $tgt_dir/wav.scp
    rm $tgt_dir/wav.scp.tmp
    
else
    echo "$tgt_dir/wav.scp already exist, no recomputing it"
fi


if [ -f $tgt_dir/spk2utt ] && [ -f $tgt_dir/utt2spk ]; then
    echo "$tgt_dir/spk2utt and $tgt_dir/utt2spk already exist, not recomputing them."
elif [ "$no_speaker_info" == "true" ]; then
    
    echo "Creating $tgt_dir/spk2utt and $tgt_dir/utt2spk"

    cut -d' ' -f1 $tgt_dir/wav.scp | awk '{print $1" "$1}' > $tgt_dir/utt2spk
    cp $tgt_dir/utt2spk $tgt_dir/spk2utt

else
    
    echo "Creating utt2spk"
    cut -d' ' -f 1 $tgt_dir/wav.scp | awk -F'_' '{print $1"_"$2"_"$3"_"$4" "$1}' | sort > $tgt_dir/utt2spk
    utils/utt2spk_to_spk2utt.pl $tgt_dir/utt2spk > $tgt_dir/spk2utt
fi

if  [ ! -f $tgt_dir/utt2lang ]; then

    #todo: instead of if statements, maybe create an additional "language" variable

    cut -d' ' -f1 $tgt_dir/wav.scp | awk -F'_' '{print $1"_"$2"_"$3"_"$4" "$2}' | sort > $tgt_dir/utt2lang    
fi

if [ ! -f $tgt_dir/utt2dur ]; then
    #Only works because utterances already segmented. Might also have to create vad.scp
    echo "Creating $tgt_dir/segments from utt2dur"
    utils/data/get_utt2dur.sh --cmd "$train_cmd" --nj 10 $tgt_dir #need to put it eparately although next script also checks for it if missing as it allows to run it using slurm.
fi

# # if [ ! -f $tgt_dir/segments ]; then
    
# #     utils/data/get_segments_for_data.sh $tgt_dir
# # else
# #     echo "$tgt_dir/segments already exist, no recomputing it"
# # fi


# utils/fix_data_dir.sh $tgt_dir
# utils/validate_data_dir.sh --no-text --no-feats $tgt_dir
