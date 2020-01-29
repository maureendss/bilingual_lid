#!/usr/bin/env python

# from local.utils.analysis.hierarchical_clustering import *
from hierarchical_clustering import *
 

def run_hc(ivecs_names, ivecs, data_dirs, label, prange, out_fig, style_list=None, legend_loc='right', yaxis=None):
    purity_list=[]
    for ivec_scp, datadir in zip(ivecs, data_dirs):                                                                                                                                 
        ivectors_df, labels_df = prepare_data(ivec_scp, datadir)                                                                                                                    
        purity_list.append(get_purity_range(prange, np.array(ivectors_df), labels_df[label]))                                                                                      
    plot_purity(purity_list, out_fig, ivecs_names, label, style_list=style_list, legend_loc=legend_loc, yaxis=yaxis)
    for p, name in zip(purity_list, ivecs_names):                                                                                                                               
        c = len(set(labels_df[label]))
        print("--------")
        print("Purity for {} clusters on {} label for {} is {}".format(c, label, name, dict((x, y) for x, y in p)[c]))     


def run_hc_average(ivecs_names, ivecs, data_dirs, averaged, label, prange, out_fig, style_list=None, legend_loc='right', yaxis=None):
    #average of form [(spk_match1, spk_match2, "spkmatch")]
    purity_list=[]
    names_list=[]
    purity_dict={}
    for ivec_scp, datadir, name in zip(ivecs, data_dirs, ivecs_names):
        # if name not in list(sum(averaged, ())): #if not one to be average, calculate it and plot it
        ivectors_df, labels_df = prepare_data(ivec_scp, datadir)                                                                                                                    
        purity_dict[name] = get_purity_range(prange, np.array(ivectors_df), labels_df[label])
        if name not in list(sum(averaged, ())):
            names_list.append(name)
            purity_list.append(purity_dict[name])

    for item in averaged:
        # print purity_dict[item[0]]
        # print purity_dict[item[1]]
        purity_dict[item[2]]=np.mean([purity_dict[item[0]], purity_dict[item[1]]], axis=0)
        names_list.append(item[2])
        purity_list.append(purity_dict[item[2]])
    
    plot_purity(purity_list, out_fig, names_list, label, style_list=style_list, legend_loc=legend_loc, yaxis=yaxis)

    
    for p, name in zip(purity_list, ivecs_names):                                                                                                                               
        c = len(set(labels_df[label]))
        print("--------")
        print("Purity for {} clusters on {} label for {} is {}".format(c, label, name, dict((x, y) for x, y in p)[c]))     




if __name__ == '__main__' :
    
    # ######### TRAIN #############
     

    # --------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    # Create Train plots per lang WITH AVERAGE ON MIX SUBSETS


    # ivecs_names=['mix_1_eng-fin', 'mix_2_eng-fin', 'mix_1_eng-ger', 'mix_2_eng-ger',\
    #              'bil_1_eng-fin', 'bil_2_eng-fin', 'bil_1_eng-ger', 'bil_2_eng-ger']

    # #Standard
    # # ivecs=['exp_emime-controlled/ivectors-deltassdc/ivectors_128_tr-train_{}_ts-train_{}/ivector.scp'.format(n, n) for n in ivecs_names]
    # # data_dirs=['data/emime-controlled/train_{}'.format(n) for n in ivecs_names]
    # # out_fig='figs/hc-controlled/hc_train_lang_standard.pdf'

    ivecs_names=['mix_1_eng-fin', 'mix_2_eng-fin', 'mix_1_eng-ger', 'mix_2_eng-ger',\
                 'bil-sent_1_eng-fin', 'bil-sent_2_eng-fin', 'bil-sent_1_eng-ger', 'bil-sent_2_eng-ger']

    #Standard
    ivecs=['exp_emime-controlled/ivectors-deltassdc/ivectors_128_tr-train_{}_ts-train_{}/ivector.scp'.format(n, n) for n in ivecs_names]
    data_dirs=['data/emime-controlled/train_{}'.format(n) for n in ivecs_names]
    out_fig='figs/hc-controlled/hc_train_lang_standard-sent.pdf'


    # #VLTN
    # ivecs=['exp_emime-controlled/vltn/ivectors-deltassdc+cmvn/ivectors_128_tr-train_{}_ts-train_{}/ivector.scp'.format(n, n) for n in ivecs_names]
    # data_dirs=['data/emime-controlled/vltn/train_{}'.format(n) for n in ivecs_names]
    # out_fig='figs/hc-controlled/hc_train_lang_vltn-sent.pdf'


    
    averaged=[('mix_1_eng-fin','mix_2_eng-fin','mix_eng-fin'), \
              ('mix_1_eng-ger','mix_2_eng-ger','mix_eng-ger'), \
              ('bil_1_eng-fin','bil_2_eng-fin','bil_eng-fin'), \
              ('bil_1_eng-ger','bil_2_eng-ger','bil_eng-ger')]


    averaged=[('mix_1_eng-fin','mix_2_eng-fin','mix_eng-fin'), \
              ('mix_1_eng-ger','mix_2_eng-ger','mix_eng-ger'), \
              ('bil-sent_1_eng-fin','bil-sent_2_eng-fin','bil_eng-fin'), \
              ('bil-sent_1_eng-ger','bil-sent_2_eng-ger','bil_eng-ger')]
    
    style_list=[('r','-.'), ('r', ':'), ('b','-.'), ('b', ':')] #keep it the length it'll be after averaged

    
    label='lang'
    yaxis=(-0.04,0.73)
    prange=(2,20)
    
    run_hc_average(ivecs_names, ivecs, data_dirs, averaged, label, prange, out_fig, style_list=style_list, yaxis=yaxis)




    

    
 #   -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
#    Create Train plots per spk. USE spkmatch this time as need all same number of spks. WITH AVERAGE ON MIX

    # ivecs_names=['mix_1_eng-fin', 'mix_2_eng-fin', 'mix_1_eng-ger', 'mix_2_eng-ger',\
    #              'bil_1_eng-fin', 'bil_2_eng-fin', 'bil_1_eng-ger', 'bil_2_eng-ger', \
    #              'mono_fin', 'mono_eng_finspk', 'mono_ger', 'mono_eng_gerspk',
    #              'mono_eng_native']


    # #Standard
    # ivecs=['exp_emime-controlled/ivectors-deltassdc/ivectors_128_tr-train_{}_ts-train_{}/ivector.scp'.format(n, n) for n in ivecs_names]
    # data_dirs=['data/emime-controlled/train_{}'.format(n) for n in ivecs_names]
    # out_fig='figs/hc-controlled/hc_train_spk_standard.pdf'


    # Standard
    ivecs_names=['mix_1_eng-fin', 'mix_2_eng-fin', 'mix_1_eng-ger', 'mix_2_eng-ger',\
                 'bil-sent_1_eng-fin', 'bil-sent_2_eng-fin', 'bil-sent_1_eng-ger', 'bil-sent_2_eng-ger', \
                 'mono_fin', 'mono_eng_finspk', 'mono_ger', 'mono_eng_gerspk',
                 'mono_eng_native']

    ivecs=['exp_emime-controlled/ivectors-deltassdc/ivectors_128_tr-train_{}_ts-train_{}/ivector.scp'.format(n, n) for n in ivecs_names]
    data_dirs=['data/emime-controlled/train_{}'.format(n) for n in ivecs_names]
    out_fig='figs/hc-controlled/hc_train_spk_standard-sent.pdf'


    # #VLTN
    # ivecs=['exp_emime-controlled/vltn/ivectors-deltassdc+cmvn/ivectors_128_tr-train_{}_ts-train_{}/ivector.scp'.format(n, n) for n in ivecs_names]
    # data_dirs=['data/emime-controlled/vltn/train_{}'.format(n) for n in ivecs_names]
    # out_fig='figs/hc-controlled/hc_train_spk_vltn-sent.pdf'
    
    averaged=[('mix_1_eng-fin','mix_2_eng-fin','mix_eng-fin'), \
              ('mix_1_eng-ger','mix_2_eng-ger','mix_eng-ger'), \
              ('bil_1_eng-fin','bil_2_eng-fin','bil_eng-fin'), \
              ('bil_1_eng-ger','bil_2_eng-ger','bil_eng-ger'), \
              ('mono_fin', 'mono_eng_finspk', 'mono_eng-fin'),
              ('mono_ger', 'mono_eng_gerspk', 'mono_eng-ger')]

    averaged=[('mix_1_eng-fin','mix_2_eng-fin','mix_eng-fin'), \
              ('mix_1_eng-ger','mix_2_eng-ger','mix_eng-ger'), \
              ('bil-sent_1_eng-fin','bil-sent_2_eng-fin','bil_eng-fin'), \
              ('bil-sent_1_eng-ger','bil-sent_2_eng-ger','bil_eng-ger'), \
              ('mono_fin', 'mono_eng_finspk', 'mono_eng-fin'),
              ('mono_ger', 'mono_eng_gerspk', 'mono_eng-ger')]
    
    style_list=[('g', '--'), ('g', '-.'), ('g', ':'),('r','-.'), ('r', ':'),('b','-.'), ('b', ':')]
    label='spk'

    yaxis=(0.0,0.58)
    prange=(12,30)
    
    run_hc_average(ivecs_names, ivecs, data_dirs, averaged, label, prange, out_fig, style_list=style_list, yaxis=yaxis)
    





    
    # # -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
    # #### Create Train plots per SENT. Doesn't really work as average is wrong (can't compare) Not even possible to do proper average as not same sizes?


    # ivecs_names=['mix_spkmatch_eng-ger', 'mix_spkmatch_eng-fin', 'bil_eng-ger', 'bil_eng-fin']
    # # ivecs=['exp_emime/ivectors-deltassdc/ivectors_128_tr-train_{}_ts-train_{}/ivector.scp'.format(n, n) for n in ivecs_names]
    # ivecs=['exp_emime/vltn/ivectors-deltassdc/ivectors_128_tr-train_{}_ts-train_{}/ivector.scp'.format(n, n) for n in ivecs_names]

    # # data_dirs=['data/emime/train_{}'.format(n) for n in ivecs_names]
    # data_dirs=['data/emime/vltn/train_{}'.format(n) for n in ivecs_names]
    # style_list=[('r','-.'), ('r', ':'), ('b','-.'), ('b', ':')]


    # label='sent'
    # # out_fig='figs/hc/emime-deltassdc/hc_train_sent.pdf'
    # out_fig='figs/hc/vltn/emime-deltassdc/hc_train_sent.pdf'
    # prange=(280,320)
    
    # run_hc(ivecs_names, ivecs, data_dirs, label, prange, out_fig, style_list=style_list)
    
