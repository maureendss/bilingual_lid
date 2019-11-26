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

    parser.parse_args()
    args, leftovers = parser.parse_known_args()

    try:
        shutil.rmtree('{}/tmp'.format(args.target_dir))
    except:
        pass

    os.makedirs('{}/tmp'.format(args.target_dir))



    with kaldiio.ReadHelper('scp:{}'.format(args.feats_file)) as reader: 
        filenames=[] 
        times=np.array([0])
        for key, numpy_array in reader: 
            filenames.append(key)
            ivector_2d = np.expand_dims(numpy_array, axis=0) 
            np.savez('{}/tmp/{}'.format(args.target_dir, key), features=ivector_2d, time=times)

            
    any2h5features.convert('{}/tmp'.format(args.target_dir), '{}/ivectors.h5f'.format(args.target_dir))

    
    shutil.rmtree('{}/tmp'.format(args.target_dir))
