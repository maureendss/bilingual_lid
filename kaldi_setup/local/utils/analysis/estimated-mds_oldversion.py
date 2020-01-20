#!/usr/bin/env python

import numpy as np
import kaldiio
from ABXpy.misc import any2h5features
import os, shutil
from sklearn.manifold import MDS
import matplotlib.pyplot as plt
from collections import defaultdict
import pandas as pd

# ADD COLOURS PER LANG
#read from feats.scp
#add feats scp direc

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("feats_file", help="path to the ivector.scp we're going to use as example")
    parser.add_argument("utt2lang", help="can also be utt2spk / utt2sent")
    parser.add_argument("output_fig", help="...")

    parser.parse_args()
    args, leftovers = parser.parse_known_args()

    # utt_dict=defaultdict(list)  
    utt2lang={}
    with open(args.utt2lang, 'r') as input_utt2lang:
        for line in input_utt2lang:
            utt2lang[line.split(' ')[0]] = line.split(' ')[1].strip('\n')
    utt2data={}


    with kaldiio.ReadHelper('scp:{}'.format(args.feats_file)) as reader: 
        for key, value in reader:
            utt2data[key] = value.astype(np.float64)
    utt_list = sorted(list(utt2lang.keys()))

    data=[]
    lang_data=[]
    for k in utt_list:
        data.append(utt2data[k])
        lang_data.append(utt2lang[k])
    data = np.matrix(data)

    lang_data=np.array(lang_data)
    
    embedding = MDS(n_components=2)
    data_transformed = embedding.fit_transform(data)


    df = pd.DataFrame(dict(x=data_transformed[:,0], y=data_transformed[:,1], label=lang_data))
    groups = df.groupby('label')
    fig, ax = plt.subplots()
    ax.margins(0.05) # Optional, just adds 5% padding to the autoscaling
    for name, group in groups:
        ax.plot(group.x, group.y, marker='o', linestyle='', ms=6, label=name)
        ax.legend()
    plt.title(args.feats_file)


    #SHOULD ALSO DO PER GENDER
    
    # plt.scatter(data_transformed[:,0],data_transformed[:,1]) 
    plt.savefig(args.output_fig)
    plt.clf()
