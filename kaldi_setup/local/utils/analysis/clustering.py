#!/usr/bin/env python

import numpy as np
import kaldiio
import matplotlib.pyplot as plt
import pandas as pd
#%matplotlib inline
plt.rcParams.update({'font.size': 18})

import numpy as np
from sklearn.cluster import AgglomerativeClustering
from sklearn.metrics.cluster import homogeneity_score
from sklearn.cluster import KMeans
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
    #hierarchical
    cluster = AgglomerativeClustering(n_clusters=c, affinity='euclidean', linkage=linkage_proc)
    data_p=cluster.fit_predict(data)
    return homogeneity_score(label_data, data_p)



def get_purity_kmeans(c, data, label_data, trials=20):
    #hierarchical
    scores=[]
    for x in range(0,trials):
        
        kmeans = KMeans(n_clusters=c, algorithm="full", random_state=None).fit(np.array(data))
        scores.append(homogeneity_score(label_data, kmeans.labels_))

    #calculate standard deviation
    sd = np.std(scores)
    score = np.mean(scores)
    return score, sd
    

def get_purity_range(c_range, data, label_data, linkage_proc='ward'):
    # if use kmeans, careful, will return a tuple with "score, standard deviation"
    #c_range is a tuple of form (2,20) if want scores for 2 to 21
    purity_range=[]
    for x in range(c_range[0], c_range[1]+1):
        purity_range.append((x, get_purity(x, data, label_data, linkage_proc=linkage_proc)))
    return purity_range

def get_purity_range_kmeans(c_range, data, label_data):
    # if use kmeans, careful, will return a tuple with "score, standard deviation"
    #c_range is a tuple of form (2,20) if want scores for 2 to 21
    purity_range=[]
    for x in range(c_range[0], c_range[1]+1):
        y,err=get_purity_kmeans(x, data, label_data)
        purity_range.append((x, y, err))
        print("purity for {} is {} with sd of {}".format(x,y,err))
    return purity_range


def plot_purity(purity_list, out_fig, ivec_names,label_name, style_list=None , legend_loc='right', yaxis=None):
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

    if legend_loc == 'right':
        lgd = plt.legend(bbox_to_anchor=(1, 0.5), loc='center left')
    elif legend_loc == 'bottom':
        lgd = plt.legend(bbox_to_anchor=(0.5, -0.05), loc='upper center')
    elif legend_loc == 'auto':
        lgd = plt.legend()
    
    else:
        raise ValueError
    plt.ylabel('{} purity'.format(label_name))
    plt.xlabel('Number of clusters')
    if yaxis:
        plt.ylim(yaxis)
    plt.savefig(out_fig,bbox_extra_artists=(lgd,), bbox_inches='tight')
    plt.close()


def plot_purity_kmeans(purity_list, out_fig, ivec_names,label_name, style_list=None , legend_loc='right', yaxis=None):
    #ivec_names i s a list of length of purity_list, with the name of each ivector for the legend
    #purity is of form [[(c_a1,purity_a1)(c_a2, purity_a2)],[(c_b1,purity_b1)(c_b2, purity_b2)]]
    #style_list is a list of same size as the purity list with tuple of color and linestyle. eg: [('r','--'), ('b', '-')]
    
    plt.figure()

    plt.subplot(211)
    ax = plt.figure().gca()
    ax.xaxis.set_major_locator(MaxNLocator(integer=True))

    if style_list:
        for group, label,style in zip(purity_list, ivec_names, style_list):
            x, y , err = zip(*group) # unpack a list of pairs into two tuples
            # plt.plot(x, y, label=label, color=style[0], linestyle=style[1])
            plt.errorbar(x, y, yerr=err, uplims=True, lolims=True, label=label, color=style[0], linestyle=style[1])
            
    else:
        for group, label in zip(purity_list, ivec_names):
            x, y, err  = zip(*group) # unpack a list of pairs into two tuples
            plt.errorbar(x, y, yerr=err, uplims=True, lolims=True, label=label)

    if legend_loc == 'right':
        lgd = plt.legend(bbox_to_anchor=(1, 0.5), loc='center left')
    elif legend_loc == 'bottom':
        lgd = plt.legend(bbox_to_anchor=(0.5, -0.05), loc='upper center')
    elif legend_loc == 'auto':
        lgd = plt.legend()
    
    else:
        raise ValueError
    # plt.ylabel('{} purity'.format(label_name))
    plt.ylabel('Language purity'.format(label_name))
    plt.xlabel('Number of clusters')
    if yaxis:
        plt.ylim(yaxis)
    plt.savefig(out_fig,bbox_extra_artists=(lgd,), bbox_inches='tight')
    plt.close()


def plot_purity_kmeans_subplots(three_purity_list, out_fig, three_ivec_names,label_name, style_list=None , legend_loc='right', yaxis=None):
    #ivec_names i s a list of length of purity_list, with the name of each ivector for the legend
    #purity is of form [[(c_a1,purity_a1)(c_a2, purity_a2)],[(c_b1,purity_b1)(c_b2, purity_b2)]]
    #style_list is a list of same size as the purity list with tuple of color and linestyle. eg: [('r','--'), ('b', '-')]
    fig, (ax1, ax2, ax3) = plt.subplots(1, 3, figsize=(10,4))

    # plt.figure()
    # ax = plt.figure().gca()
    # ax.xaxis.set_major_locator(MaxNLocator(integer=True))
    for subplot, purity_list, ivec_names in zip([ax1,ax2,ax3], three_purity_list,three_ivec_names):
        if style_list:
            for group, label,style in zip(purity_list, ivec_names, style_list):
                x, y , err = zip(*group) # unpack a list of pairs into two tuples
                # plt.plot(x, y, label=label, color=style[0], linestyle=style[1])
                subplot.errorbar(x, y, yerr=err, uplims=True, lolims=True, label=label, color=style[0], linestyle=style[1])
        else:
            for group, label in zip(purity_list, ivec_names):
                x, y, err  = zip(*group) # unpack a list of pairs into two tuples
                subplot.errorbar(x, y, yerr=err, uplims=True, lolims=True, label=label)
        subplot.ylabel('{} purity'.format(label_name))
        subplot.xlabel('Number of clusters')
        subplot.set_ylim(list(yaxis))
        # subplot.ylabel('{} purity'.format(label_name))
        # subplot.xlabel('Number of clusters')
        # if yaxis:
        #     subplot.ylim(yaxis)
    # fig.ylabel('{} purity'.format(label_name))
    # fig.xlabel('Number of clusters')        
    # if yaxis:
    #     fig.ylim(yaxis)
    if legend_loc == 'right':
        lgd = fig.legend(bbox_to_anchor=(1, 0.5), loc='center left')
    elif legend_loc == 'bottom':
        lgd = fig.legend(bbox_to_anchor=(0.5, -0.05), loc='upper center')
    elif legend_loc == 'auto':
        lgd = fig.legend()
    else:
        raise ValueError
    plt.savefig(out_fig,bbox_extra_artists=(lgd,), bbox_inches='tight')
    plt.close()
