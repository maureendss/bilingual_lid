#!/usr/bin/env python

import numpy as np
import kaldiio



#read from feats.scp
#add feats scp direc

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("feats_file", help="path to the feats.scp we're going to use as example")
    parser.add_argument("target_file", help="path to target file (without the scp extension)")
    parser.add_argument("--filler", type=int, default=1, help="value to fille the matrix with (1 or 0)")

    parser.parse_args()
    args, leftovers = parser.parse_known_args()



    with kaldiio.ReadHelper('scp:{}'.format(args.feats_file)) as reader: 
        feats={} 
        for key, numpy_array in reader: 
            feats[key] = numpy_array


    with kaldiio.WriteHelper('ark,scp:{}.ark,{}.scp'.format(args.target_file, args.target_file)) as writer: 
        for key, value in feats.items():
            vec= np.full(len(value), args.filler, dtype=np.float32) 
            writer(key, vec) 
               
