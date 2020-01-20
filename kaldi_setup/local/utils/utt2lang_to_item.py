#!/usr/bin/env python

import numpy as np
import os, shutil
import warnings


#read from feats.scp
#add feats scp direc

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("datadir", help="path to data directory (should contain utt2spk, utt2lang and will output ivectors.item).")
    parser.add_argument("output_dir", help="path to the output directory where ivectors.item will be created")
    parser.add_argument("--ivector_dim", type=int, default=600, help="ivector_dimensions")
    parser.parse_args()
    args, leftovers = parser.parse_known_args()

    try:
        os.makedirs('{}/tmp'.format(args.path_to_output))
    except:
        pass

    if args.ivector_dim == 600:
        warnings.warn("Warning: using the default value for I-Vector dims of 600. Please use --ivector_dim if your value is different.")

    #Create .item files
    with open("{}/utt2lang".format(args.datadir), 'r') as input_utt2lang:
        utt2lang_dict={}
        for line in input_utt2lang:
            utt2lang_dict[line.split(' ')[0]] = line.split(' ')[1].strip('\n')

    with open("{}/utt2spk".format(args.datadir), 'r') as input_utt2spk:
        utt2spk_dict={}
        for line in input_utt2spk:
            utt2spk_dict[line.split(' ')[0]] = line.split(' ')[1].strip('\n')


    if os.path.isfile("{}/utt2sent".format(args.datadir)):
        with open("{}/utt2sent".format(args.datadir), 'r') as input_utt2sent:
            utt2sent_dict={}
            for line in input_utt2sent:
                utt2sent_dict[line.split(' ')[0]] = line.split(' ')[1].strip('\n')

    
    utt_list = sorted(list(utt2lang_dict.keys()))
    with open('{}/ivectors.item'.format(args.output_dir), 'w') as output:
        if os.path.isfile("{}/utt2sent".format(args.datadir)):
            output.write('#file onset offset #lang spk sent\n')
        else:
            output.write('#file onset offset #lang spk\n')
            
        for utt in utt_list:
            if os.path.isfile("{}/utt2sent".format(args.datadir)):
                output.write("{} {} {} {} {} {}\n".format(utt, 0, args.ivector_dim, utt2lang_dict[utt], utt2spk_dict[utt], utt2sent_dict[utt]))    
            else:
                output.write("{} {} {} {} {}\n".format(utt, 0, args.ivector_dim, utt2lang_dict[utt], utt2spk_dict[utt]))
        
        
