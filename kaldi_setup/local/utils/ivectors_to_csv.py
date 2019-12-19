#!/usr/bin/env python

import numpy as np
import kaldiio
from ABXpy.misc import any2h5features
import os, shutil
import pandas as pd

#read from feats.scp
#add feats scp direc

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("feats_file", help="path to the ivector.scp we're going to use as example")
    parser.add_argument("target_dir", help="path to target dir")
    parser.add_argument("--output_name", type=str, default="ivector.csv", help="name to output file (ivectors.csv or lda_ivectors.csv")
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

        df = pd.DataFrame()
        
        for key, numpy_array in reader: 
            filenames.append(key)
            s = pd.Series(numpy_array)
            s.name = key
            df = df.append(s)

    df.to_csv('{}/{}'.format(args.target_dir, args.output_name), header=False)

    
