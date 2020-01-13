#!/usr/bin/env python

import numpy as np
import os, shutil
from collections import defaultdict
import random

#WARNING TO NOT USE
#NECESSITATE A SPECIAL "utt2spk_lang file instead of utt2spk with speaker as "FM3_ENG" - important for bilingual train set. 

def retrieve_meta(utt2dur, utt2spk):

    utt2dur_dict= {}
    utt2spk_dict= {}
    spk2utt_dict = defaultdict(list)
    
    with open(utt2dur, 'r') as dur_file: 
        for l in dur_file:
            utt2dur_dict[l.split()[0]] = float(l.split()[1])
    with open(utt2spk, 'r') as spk_file: 
        for l in spk_file:
            utt2spk_dict[l.split()[0]] = l.split()[1]
            spk2utt_dict[l.split()[1]].append(l.split()[0])
            
            
    return utt2dur_dict, utt2spk_dict, spk2utt_dict



def get_duration(max_dur, utt2dur_dict, utt2spk_dict, spk2utt_dict):
    num_spk = len(spk2utt_dict)
    dur_per_spk = round(float(max_dur)/num_spk)
    print("Trying to match an average duration on {} seconds for each of the {} speakers".format(dur_per_spk, num_spk))
    final_utts = []
    
    #now try to match this.  Make it in real stupid way in that just pick until goes above value. TODO: make it more efficient by finding the best possible match.

    #JUST IN CASE ONE SPEAKER DOESN'T HAVE ENOUGH UTTERANCES
    total_sum=0
    left_pool=[]


    
    for spk in spk2utt_dict.keys():
        # if args.pick_from_all:
        #     utt_pool = spk2utt_dict[spk]
        # else:
        #     utt_pool = [x for x in spk2utt_dict[spk] if x[-1] == "0"]

        #Do the thing below so that forst pick only 0s and then 1s only if not enough to match duration
        utt_pool_0s = [x for x in spk2utt_dict[spk] if x[-1] == "0"]
        random.shuffle(utt_pool_0s)
        utt_pool_1s = [x for x in spk2utt_dict[spk] if x[-1] == "1"]
        random.shuffle(utt_pool_1s)
        utt_pool = utt_pool_1s + utt_pool_0s


        
        tmp_utt = []
        tmp_sum=0
        while tmp_sum < dur_per_spk - 2: # give 1 sec layoff
            try:
                utt = utt_pool.pop()
                tmp_utt.append(utt)
                tmp_sum += utt2dur_dict[utt]
            except:
                print("It seems that the goal max duration per speaker is bigger than the actual total duration for speaker {}. Will try to fill in later.".format(spk))
                break
            
                # raise ValueError("It seems that the goal max duration per speaker is bigger than the actual total duration for speaker {}".format(spk))
            
        final_utts.extend(tmp_utt)
        total_sum+=tmp_sum
        left_pool.extend(utt_pool)
        print("Total duration for speaker {} is {} seconds".format(spk, tmp_sum))

    if total_sum < max_dur - 3 : #if couldn't find enough per speaker
        tmp_left_pool_0s = [x for x in left_pool if x[-1] == "0"]
        tmp_left_pool_1s = [x for x in left_pool if x[-1] == "1"]
        left_pool_0s = [ x[0] for x in sorted(utt2dur_dict.items(), key=lambda kv: kv[1], reverse = True) if x[0] in tmp_left_pool_0s]
        left_pool_1s = [ x[0] for x in sorted(utt2dur_dict.items(), key=lambda kv: kv[1], reverse = True) if x[0] in tmp_left_pool_1s] 
        left_pool = left_pool_1s + left_pool_0s
        while total_sum < max_dur - 3: #give a layoff of 5 seconds otherwise go over too muchOA

            try:
                # sort per duration
                utt = left_pool.pop()
                final_utts.append(utt)
                total_sum += utt2dur_dict[utt]
                
            except:
                raise ValueError("Not enough utterances to match the goal max duration")

    print("Final Total duration is of {} seconds".format(total_sum))
    return final_utts


def write_final_output(final_utts_list, output_file):
    with open(output_file, 'w') as output:
        for x in final_utts_list:
            output.write("{}\n".format(x))

              
if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("max_dur", type=float, help="max duration in seconds requested in total in file")
    parser.add_argument("utt2dur", help="file to utt2dur")
    parser.add_argument("utt2spk", help="path to utt2spk")
    parser.add_argument("output_file", help="path to output utt file")
    parser.add_argument("--pick_from_all", default=False, action="store_true" , help="If set, we will pick utterances independantly from both '0's and '1's utterances - only works for emime dataset. Better to leave it to false so that only '0's versions are picked from to ensure more diversity")
    parser.parse_args()
    args, leftovers = parser.parse_known_args()


    utt2dur_dict, utt2spk_dict, spk2utt_dict = retrieve_meta(args.utt2dur, args.utt2spk)
    utt_list = get_duration(args.max_dur, utt2dur_dict, utt2spk_dict, spk2utt_dict)
    write_final_output(utt_list, args.output_file)
