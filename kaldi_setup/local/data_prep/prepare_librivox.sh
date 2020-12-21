 #!/usr/bin/env bash



. ./cmd.sh
. ./path.sh
. utils/parse_options.sh



set -e # exit on error

if [ $# != 3 ]; then
   echo "usage: local/data_prep/prepare_librivox.sh <lb_processed_directory> <target_data_dir> |LANG|"
   echo "e.g.:  local/data/prep/prepare_librivox.sh ~/data/speech/librivox/english/processed/LFE/10h_4spk ENG"
   exit 1;
fi

lb_directory=$1
tgt_dir=$2
lang=$3
# first put here info on how to get wav list.  


# wav.scp format <utt> <path_wav>
# assumes you have a wav directory with all wavs in it, and with only the utterance name (symlinks to their proper location)

mkdir -p $tgt_dir

if [ ! -f $tgt_dir/wav.scp ]; then
    echo "Creating $tgt_dir/wav.scp"

    for x in $lb_directory/*/*/*; do
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

else
    
    echo "Creating utt2spk"
    cut -d' ' -f 1 $tgt_dir/wav.scp | awk -F'-' '{print $1"-"$2"-"$3" "$1}' | sort > $tgt_dir/utt2spk
    utils/utt2spk_to_spk2utt.pl $tgt_dir/utt2spk > $tgt_dir/spk2utt
fi

if  [ ! -f $tgt_dir/utt2lang ]; then

    #todo: instead of if statements, maybe create an additional "language" variable
  
    cut -d' ' -f1 $tgt_dir/wav.scp | awk -v var="$lang" -F'-' '{print $1"-"$2"-"$3" "var}' | sort > $tgt_dir/utt2lang    
fi

if [ ! -f $tgt_dir/utt2dur ]; then
    #Only works because utterances already segmented. Might also have to create vad.scp
    echo "Creating $tgt_dir/segments from utt2dur"
    utils/data/get_utt2dur.sh --cmd "$train_cmd" --nj 10 $tgt_dir #need to put it eparately although next script also checks for it if missing as it allows to run it using slurm.
fi

