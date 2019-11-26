#!/usr/bin/env python

import numpy as np
import os, shutil
import warnings


#read from feats.scp
#add feats scp direc

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("utt2lang", help="path to utt2lang")
    parser.add_argument("path_to_output", help="path to output ivectors.item.")
    parser.add_argument("--ivector_dim", type=int, default=600, help="ivector_dimensions")
    parser.parse_args()
    args, leftovers = parser.parse_known_args()

    try:
        os.makedirs('{}/tmp'.format(args.path_to_output))
    except:
        pass

    if args.ivector_dim == 600:
        warnings.warn("Warning: using the default value for I-Vector dims of 600. Please use --ivector_dim if your value is different.")

    #Create .item files.
    with open(args.utt2lang, 'r') as input_utt2lang:
        utt2lang_dict={}
        for line in input_utt2lang:
            utt2lang_dict[line.split(' ')[0]] = line.split(' ')[1]

    utt_list = sorted(list(utt2lang_dict.keys()))
    with open('{}/ivectors.item'.format(args.path_to_output), 'w') as output:
        output.write('#file onset offset #lang\n')
        for utt in utt_list:
            output.write("{} {} {} {}".format(utt, 0, args.ivector_dim, utt2lang_dict[utt]))
        
        
