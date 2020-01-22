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
from matplotlib.ticker import MaxNLocator

#just notes on log reg. Not to be run as is.

#train='train_bil_eng-ger'


def prepare_data(ivec_scp, data_dir):
    
    with kaldiio.ReadHelper('scp:'+ivec_scp) as reader:
        ivectors={}
        for k, iv in reader:
            ivectors[k]=iv


    with open('{}/utt2lang'.format(data_dir), 'r') as input_utt2lang:
        utt2lang_dict={}
        for line in input_utt2lang:
            utt2lang_dict[line.split(' ')[0]] = line.split(' ')[1].strip('\n')

    with open('{}/utt2spk'.format(data_dir), 'r') as input_utt2spk:
        utt2spk_dict={}
        for line in input_utt2spk:
            utt2spk_dict[line.split(' ')[0]] = line.split(' ')[1].strip('\n')

    with open('{}/utt2sent'.format(data_dir), 'r') as input_utt2sent:
        utt2sent_dict={}
        for line in input_utt2sent:
            utt2sent_dict[line.split(' ')[0]] = line.split(' ')[1].strip('\n')
            
    ivectors_df = pd.DataFrame.from_dict(ivectors, orient='index').sort_index()
    labels_df = pd.DataFrame.from_dict(utt2lang_dict, orient='index', columns=["lang"]).sort_index()
    labels_df["spk"]=pd.DataFrame.from_dict(utt2spk_dict, orient='index')
    labels_df["sent"]=pd.DataFrame.from_dict(utt2sent_dict, orient='index')

    data=np.array(ivectors_df)

    return ivectors_df, labels_df




def get_purity(c, data, label_data, linkage_proc='ward'):
    cluster = AgglomerativeClustering(n_clusters=c, affinity='euclidean', linkage=linkage_proc)
    data_p=cluster.fit_predict(data)
    return homogeneity_score(label_data, data_p)
    

def get_purity_range(c_range, data, label_data, linkage_proc='ward'):
    #c_range is a tuple of form (2,20) if want scores for 2 to 21
    purity_range=[]
    for x in range(c_range[0], c_range[1]+1):
        purity_range.append((x, get_purity(x, data, label_data, linkage_proc=linkage_proc)))
    return purity_range


def plot_purity(purity_list, out_fig, ivec_names,label_name, style_list=None ):
    #ivec_names i s a list of length of purity_list, with the name of each ivector for the legend
    #purity is of form [[(c_a1,purity_a1)(c_a2, purity_a2)],[(c_b1,purity_b1)(c_b2, purity_b2)]]
    #style_list is a list of same size as the purity list with tuple of color and linestyle. eg: [('r','--'), ('b', '-')]
    
    plt.figure()

    plt.subplot(211)
    ax = plt.figure().gca()
    ax.xaxis.set_major_locator(MaxNLocator(integer=True))

    if style_list:
        for group, label,style in zip(purity_list, ivec_names, style_list):
            x, y = zip(*group) # unpack a list of pairs into two tuples
            plt.plot(x, y, label=label, color=style[0], linestyle=style[1])
    else:
        for group, label in zip(purity_list, ivec_names):
            x, y = zip(*group) # unpack a list of pairs into two tuples
            plt.plot(x, y, label=label)

#    plt.legend()    
#    plt.legend(loc=9, bbox_to_anchor=(0.5, -0.1), ncol=2)
    lgd = plt.legend(bbox_to_anchor=(1, 0.5), loc='center left')
    plt.ylabel('{} purity'.format(label_name))
    plt.xlabel('Number of clusters')
    plt.savefig(out_fig,bbox_extra_artists=(lgd,), bbox_inches='tight')
    plt.close()
# if __name__ == "__main__":
#     import argparse

#     parser = argparse.ArgumentParser()
#     parser.add_argument("ivec_scp", help="")
#     parser.add_argument("data_dir", help="")
#     #    parser.add_argument("output_dendrogram", help="")
#     parser.add_argument('out_fig')
#     parser.add_argument('--plot', dest='plot', action='store_true')

#     parser.parse_args()
#     args, leftovers = parser.parse_known_args()



#     ivectors_df, labels_df = prepare_data(args.ivec_scp, args.data_dir) 

#     get_purity(2, data, labels_df['lang'], linkage='ward')


#     data=np.array(ivectors_df)
#     #ivectors_df = pd.DataFrame.from_dict(ivectors, orient='index')




ivecs = ['exp_emime/ivectors-deltassdc/ivectors_128_tr-train_mix_eng-ger_ts-train_mix_eng-ger/ivector.scp', 'exp_emime/ivectors-deltassdc/ivectors_128_tr-train_mix_eng-fin_ts-train_mix_eng-fin/ivector.scp', 'exp_emime/ivectors-deltassdc/ivectors_128_tr-train_bil_eng-ger_ts-train_bil_eng-ger/ivector.scp', 'exp_emime/ivectors-deltassdc/ivectors_128_tr-train_bil_eng-fin_ts-train_bil_eng-fin/ivector.scp']

data_dirs= ['data/emime/train_mix_eng-ger', 'data/emime/train_mix_eng-fin', 'data/emime/train_bil_eng-ger', 'data/emime/train_bil_eng-fin']
ivecs_names=['mix_eng-ger', 'mix_eng-fin', 'bil_eng-ger', 'bil_eng-fin']
style_list=[('r','-.'), ('b', '-.'), ('r',':'), ('b', ':')]


purity_list=[]
for ivec_scp, datadir in zip(ivecs, data_dirs):
    ivectors_df, labels_df = prepare_data(ivec_scp, datadir)
    purity_list.append(get_purity_range((2,20), np.array(ivectors_df), labels_df['lang']))

plot_purity(purity_list, 'tmp.svg', ivecs_names, 'lang', style_list=style_list) 
