#!/usr/bin/env python

import numpy as np
import kaldiio
from ABXpy.misc import any2h5features
import os, shutil

#read from feats.scp
#add feats scp direc

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("feats_file", help="path to the ivector.scp we're going to use as example")
    parser.add_argument("target_dir", help="path to target dir")
    parser.add_argument("--output_name", type=str, default="ivector.h5f", help="name to output file (ivectors.h5f or lda_ivectors.h5f")
    parser.parse_args()
    args, leftovers = parser.parse_known_args()


    print(args.output_name)
    try:
        shutil.rmtree('{}/tmp'.format(args.target_dir))
    except:
        pass


    if os.path.exists('{}/{}'.format(args.target_dir, args.output_name)):
        os.remove('{}/{}'.format(args.target_dir, args.output_name))
    
    os.makedirs('{}/tmp'.format(args.target_dir))



    with kaldiio.ReadHelper('scp:{}'.format(args.feats_file)) as reader: 
        filenames=[] 
        times=np.array([0])  
        for key, numpy_array in reader: 
            filenames.append(key)
            ivector_2d = np.expand_dims(numpy_array.astype(np.float64), axis=0) 
            np.savez('{}/tmp/{}'.format(args.target_dir, key), features=ivector_2d, time=times)
    print('aaa')
    any2h5features.convert('{}/tmp/'.format(args.target_dir), '{}/{}'.format(args.target_dir, args.output_name))
    print('bbb')
    
    # shutil.rmtree('{}/tmp'.format(args.target_dir))
