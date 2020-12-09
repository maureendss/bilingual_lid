#!/usr/bin/env bash
#Not possible as LDA on lang but only one lang.
./local/exp/run_langfam.sh --train_ger "train_mono_eng_native" --train_fin "train_mono_eng_native" --test_ger "train_bil_1_eng-ger" --test_fin "train_bil_1_eng-fin"

./local/exp/run_langfam.sh --train_ger "train_mono_eng_native" --train_fin "train_mono_eng_native" --test_ger "train_bil_2_eng-ger" --test_fin "train_bil_2_eng-fin"

./local/exp/run_langfam.sh  --train_ger "train_mono_eng_native" --train_fin "train_mono_eng_native" --test_ger "train_mix_1_eng-ger" --test_fin "train_mix_1_eng-fin"

./local/exp/run_langfam.sh  --train_ger "train_mono_eng_native" --train_fin "train_mono_eng_native" --test_ger "train_mix_2_eng-ger" --test_fin "train_mix_2_eng-fin"

