 #!/usr/bin/env bash


no_speaker_info=false #We pretend each utterance comes from different speaker. (Just for practicity purposes Probably not needed as we won't generate cmvn but never know. Would have to compare). 



. ./cmd.sh
. ./path.sh
. utils/parse_options.sh



set -e # exit on error

if [ $# != 3 ]; then
   echo "usage: local/prepare_xitsonga_english.sh <utt_list> <wav_directory> <target_data_dir>"
   echo "e.g.:  local/prepare_xitsonga_english.sh data/xitsonga-english/lists/train_english.txt data/xitsonga-english/wavs/ data/english-xitsonga/train_timit"
   exit 1;
fi

utt_list=$1
wav_directory=$2
tgt_dir=$3

# first put here info on how to get wav list.  


# wav.scp format <utt> <path_wav>
# assumes you have a wav directory with all wavs in it, and with only the utterance name (symlinks to their proper location)

mkdir -p $tgt_dir

if [ ! -f $tgt_dir/wav.scp ]; then
    echo "Creating $tgt_dir/wav.scp"
    awk -v x=$wav_directory '{print $1, "sox "x"/"$1".wav -t wav - |"}' $utt_list > $tgt_dir/wav.scp
else
    echo "$tgt_dir/wav.scp already exist, no recomputing it"
fi


if [ -f $tgt_dir/spk2utt ] && [ -f $tgt_dir/utt2spk ]; then
    echo "$tgt_dir/spk2utt and $tgt_dir/utt2spk already exist, not recomputing them."
elif [ "$no_speaker_info" == "true" ]; then
    
    echo "Creating $tgt_dir/spk2utt and $tgt_dir/utt2spk"

    awk '{print $1" "$1}' $utt_list > $tgt_dir/utt2spk
    cp $tgt_dir/utt2spk $tgt_dir/spk2utt

else
    
    if [[ $(basename ${utt_list}) == *"english"* ]]; then
        echo "Creating utt2spk english"
        awk -F'_' '{print $1"_"$2" "$1}' $utt_list | sort > $tgt_dir/utt2spk
        utils/utt2spk_to_spk2utt.pl $tgt_dir/utt2spk > $tgt_dir/spk2utt
    elif [[ $(basename ${utt_list}) == *"xitsonga"* ]]; then
        echo "Creating utt2spk xitsonga"
        awk -F'_' '{print $1"_"$2"_"$3"_"$4" "$1"_"$2"_"$3}' $utt_list | sort > $tgt_dir/utt2spk
        utils/utt2spk_to_spk2utt.pl $tgt_dir/utt2spk > $tgt_dir/spk2utt
    else
        echo "--- Couldn't figure out what language the utt_list contains. Please create $tgt_dir/utt2spk and spk2utt manually ---"
    fi

    
fi

if  [ ! -f $tgt_dir/utt2lang ]; then

    #todo: instead of if statements, maybe create an additional "language" variable
    if [[ $(basename ${utt_list}) == *"english"* ]]; then
        awk '{print $1" english"}' $utt_list | sort > $tgt_dir/utt2lang
    elif [[ $(basename ${utt_list}) == *"xitsonga"* ]]; then 
        awk '{print $1" xitsonga"}' $utt_list | sort > $tgt_dir/utt2lang
    else
        echo "--- Couldn't figure out what language the utt_list contains. Please create $tgt_dir/utt2lang manually ---"
    fi
    
fi

if [ ! -f $tgt_dir/utt2dur ]; then
    #Only works because utterances already segmented. Might also have to create vad.scp
    echo "Creating $tgt_dir/segments from utt2dur"
    utils/data/get_utt2dur.sh --cmd "$train_cmd" $tgt_dir #need to put it eparately although next script also checks for it if missing as it allows to run it using slurm.
fi

# if [ ! -f $tgt_dir/segments ]; then
    
#     utils/data/get_segments_for_data.sh $tgt_dir
# else
#     echo "$tgt_dir/segments already exist, no recomputing it"
# fi


utils/fix_data_dir.sh $tgt_dir
utils/validate_data_dir.sh --no-text --no-feats $tgt_dir
