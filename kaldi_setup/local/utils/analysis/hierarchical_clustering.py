#!/usr/bin/env python

import numpy as np
import kaldiio
import matplotlib.pyplot as plt
import pandas as pd
#%matplotlib inline
import numpy as np
from sklearn.cluster import AgglomerativeClustering
from sklearn.metrics.cluster import homogeneity_score
import scipy.cluster.hierarchy as shc

#just notes on log reg. Not to be run as is.

#train='train_bil_eng-ger'

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("ivec_scp", help="")
    parser.add_argument("data_dir", help="")
#    parser.add_argument("output_dendrogram", help="")
    parser.add_argument('--plot', dest='plot', action='store_true')
    parser.parse_args()
    args, leftovers = parser.parse_known_args()


    with kaldiio.ReadHelper('scp:'+args.ivec_scp) as reader:
        ivectors={}
        for k, iv in reader:
            ivectors[k]=iv


    with open('{}/utt2lang'.format(args.data_dir), 'r') as input_utt2lang:
        utt2lang_dict={}
        for line in input_utt2lang:
            utt2lang_dict[line.split(' ')[0]] = line.split(' ')[1].strip('\n')

    with open('{}/utt2spk'.format(args.data_dir), 'r') as input_utt2spk:
        utt2spk_dict={}
        for line in input_utt2spk:
            utt2spk_dict[line.split(' ')[0]] = line.split(' ')[1].strip('\n')

    with open('{}/utt2sent'.format(args.data_dir), 'r') as input_utt2sent:
        utt2sent_dict={}
        for line in input_utt2sent:
            utt2sent_dict[line.split(' ')[0]] = line.split(' ')[1].strip('\n')

            
    ivectors_df = pd.DataFrame.from_dict(ivectors, orient='index').sort_index()

    labels_df = pd.DataFrame.from_dict(utt2lang_dict, orient='index', columns=["lang"]).sort_index()
    labels_df["spk"]=pd.DataFrame.from_dict(utt2spk_dict, orient='index')
    labels_df["sent"]=pd.DataFrame.from_dict(utt2sent_dict, orient='index')

    #data = np.array(list(ivectors.values().sort()))
    data=np.array(ivectors_df)
    #ivectors_df = pd.DataFrame.from_dict(ivectors, orient='index')
    cluster = AgglomerativeClustering(n_clusters=2, affinity='euclidean', linkage='ward')
    data_p=cluster.fit_predict(data)


    #max number of clusters for perfect purity score

    homog_lang=[]
    for c in range(len(set(labels_df["lang"]))+1, 21):
        cluster = AgglomerativeClustering(n_clusters=c, affinity='euclidean', linkage='ward')
        data_p=cluster.fit_predict(data)
        homog_score = homogeneity_score(data_p, labels_df["lang"])
        homog_lang.append((c, homog_score))

    homog_spk=[]
    for c in range(len(set(labels_df["spk"]))+1, 21):
        cluster = AgglomerativeClustering(n_clusters=c, affinity='euclidean', linkage='ward')
        data_p=cluster.fit_predict(data)
        homog_score = homogeneity_score(data_p, labels_df["spk"])
        homog_spk.append((c, homog_score))


    # print("Purity is reached for lang with {} clusters".format(c))

    
    # c=len(set(labels_df["lang"])) -1 
    # homog_score=0.0
    # while homog_score < 1.0:
    #     if c > len(data):
    #         print("Clusters never reaching lang purity for {}".format(args.ivec_scp))
    #     c += 1
    #     cluster = AgglomerativeClustering(n_clusters=c, affinity='euclidean', linkage='ward')
    #     data_p=cluster.fit_predict(data)
    #     homog_score = homogeneity_score(data_p, labels_df["lang"])
    #     print("Homog of {} with {} clusters".format(homog_score, c))

    # print("Purity is reached for lang with {} clusters".format(c))


    # c=len(set(labels_df["spk"])) -1
    # homog_score=0.0
    # while homog_score < 1.0:
    #     if c > len(data):
    #         print("Clusters never reaching speaker purity for {}".format(args.ivec_scp))
    #     c += 1
    #     cluster = AgglomerativeClustering(n_clusters=c, affinity='euclidean', linkage='ward')
    #     data_p=cluster.fit_predict(data)
    #     homog_score = homogeneity_score(data_p, labels_df["spk"])
    #     print("Homog of {} with {} clusters".format(homog_score, c))

    # print("Purity is reached for spk with {} clusters".format(c))


    # c=len(set(labels_df["sent"])) -1
    # homog_score=0.0
    # while homog_score < 1.0:
    #     if c > len(data):
    #         print("Clusters never reaching sentence purity for {}".format(args.ivec_scp))
    #     c += 1 
    #     cluster = AgglomerativeClustering(n_clusters=c, affinity='euclidean', linkage='ward')
    #     data_p=cluster.fit_predict(data)
    #     homog_score = homogeneity_score(data_p, labels_df["sent"])
    #     print("Homog of {} with {} clusters".format(homog_score, c))
        
    # print("Purity is reached for sent with {} clusters".format(c))



    if args.plot:
        #dendogram plot
        plt.figure(figsize=(10, 7))
        plt.title("Dendograms for {}".format(args.ivec_scp.split('/')[2]))
        dend = shc.dendrogram(shc.linkage(data, method='ward'))
        plt.savefig(args.output_dendrogram)


    
