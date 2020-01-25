#!/usr/bin/env python

# from local.utils.analysis.hierarchical_clustering import *
from hierarchical_clustering import *
 

def run_hc(ivecs_names, ivecs, data_dirs, label, prange, out_fig, style_list=None, legend_loc='right'):
    purity_list=[]
    for ivec_scp, datadir in zip(ivecs, data_dirs):                                                                                                                                 
        ivectors_df, labels_df = prepare_data(ivec_scp, datadir)                                                                                                                    
        purity_list.append(get_purity_range(prange, np.array(ivectors_df), labels_df[label]))                                                                                      
        plot_purity(purity_list, out_fig, ivecs_names, label, style_list=style_list, legend_loc=legend_loc)                                                                                                
    for p, name in zip(purity_list, ivecs_names):                                                                                                                               
        c = len(set(labels_df[label]))
        print("--------")
        print("Purity for {} clusters on {} label for {} is {}".format(c, label, name, dict((x, y) for x, y in p)[c]))     






if __name__ == '__main__' :
    
    ######### TRAIN #############
    

    # --------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    # Create Train plots per lang
    ivecs_names=['mix_spkmatch_eng-ger', 'mix_spkmatch_eng-fin', 'bil_eng-ger', 'bil_eng-fin']
    # ivecs=['exp_emime/ivectors-deltassdc/ivectors_128_tr-train_{}_ts-train_{}/ivector.scp'.format(n, n) for n in ivecs_names]
    ivecs=['exp_emime/vltn/ivectors-deltassdc/ivectors_128_tr-train_{}_ts-train_{}/ivector.scp'.format(n, n) for n in ivecs_names]

    # data_dirs=['data/emime/train_{}'.format(n) for n in ivecs_names]
    data_dirs=['data/emime/vltn/train_{}'.format(n) for n in ivecs_names]
    # style_list=[('r','-.'), ('b', '-.'), ('r',':'), ('b', ':')]
    style_list=[('r','-.'), ('r', ':'), ('b','-.'), ('b', ':')]
    label='lang'
    # out_fig='figs/hc/emime-deltassdc/hc_train_lang.pdf'
    out_fig='figs/hc/vltn/emime-deltassdc/hc_train_lang.pdf'
    prange=(2,20)
    
    run_hc(ivecs_names, ivecs, data_dirs, label, prange, out_fig, style_list=style_list)
    
    
    # -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #### Create Train plots per spk. USE spkmatch this time as need all same number of spks.
    
    ivecs_names=['mono_eng_native', 'mono_eng', 'mono_ger', 'mono_fin', 'mix_spkmatch_eng-ger', 'mix_spkmatch_eng-fin', 'bil_eng-ger', 'bil_eng-fin']
    # ivecs=['exp_emime/ivectors-deltassdc/ivectors_128_tr-train_{}_ts-train_{}/ivector.scp'.format(n, n) for n in ivecs_names]
    ivecs=['exp_emime/vltn/ivectors-deltassdc/ivectors_128_tr-train_{}_ts-train_{}/ivector.scp'.format(n, n) for n in ivecs_names]

    # data_dirs=['data/emime/train_{}'.format(n) for n in ivecs_names]
    data_dirs=['data/emime/vltn/train_{}'.format(n) for n in ivecs_names]
    style_list=[('g', '-'), ('g', '--'), ('g', '-.'), ('g', ':'), ('r','-.'), ('r', ':'), ('b','-.'), ('b', ':')]
    label='spk'
    # out_fig='figs/hc/emime-deltassdc/hc_train_spk.pdf'
    out_fig='figs/hc/vltn/emime-deltassdc/hc_train_spk.pdf'
    prange=(12,30)
    
    run_hc(ivecs_names, ivecs, data_dirs, label, prange, out_fig, style_list=style_list)
    
    
    # -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
    #### Create Train plots per SENT
    
    ivecs_names=['mix_spkmatch_eng-ger', 'mix_spkmatch_eng-fin', 'bil_eng-ger', 'bil_eng-fin']
    # ivecs=['exp_emime/ivectors-deltassdc/ivectors_128_tr-train_{}_ts-train_{}/ivector.scp'.format(n, n) for n in ivecs_names]
    ivecs=['exp_emime/vltn/ivectors-deltassdc/ivectors_128_tr-train_{}_ts-train_{}/ivector.scp'.format(n, n) for n in ivecs_names]

    # data_dirs=['data/emime/train_{}'.format(n) for n in ivecs_names]
    data_dirs=['data/emime/vltn/train_{}'.format(n) for n in ivecs_names]
    style_list=[('r','-.'), ('r', ':'), ('b','-.'), ('b', ':')]
    label='sent'
    # out_fig='figs/hc/emime-deltassdc/hc_train_sent.pdf'
    out_fig='figs/hc/vltn/emime-deltassdc/hc_train_sent.pdf'
    prange=(280,320)
    
    run_hc(ivecs_names, ivecs, data_dirs, label, prange, out_fig, style_list=style_list)
    
    
    # ######### TEST #############
    
    # #----------------------------
    # #------- LANG ---------------
    
    # for lang in ['fin', 'ger']:
    #     for t_type in ['bil', 'mono']:

    #         # -----------------------------------------------------------------------------------------------------------------------------------------------------------------
            
    #         ivecs_names=['mono_eng_native', 'mono_eng','mono_{}'.format(lang),'mix_spkmatch_eng-{}'.format(lang), 'bil_eng-{}'.format(lang)]
    #         ivecs_test_name='test_eng-{}-{}'.format(lang,t_type)
    #         ivecs=['exp_emime/ivectors-deltassdc/ivectors_128_tr-train_{}_ts-{}/ivector.scp'.format(n, ivecs_test_name) for n in ivecs_names]                                                                       
    #         data_dirs=['data/emime/{}'.format(ivecs_test_name)]*len(ivecs_names)     
    #         style_list=[('g','-'), ('g', '--'), ('g', '-.'),('r', ':'), ('b',':')]
    #         label='lang'
    #         out_fig='figs/hc/emime-deltassdc/hc_test_{}_lang_eng-{}.pdf'.format(t_type, lang)
    #         prange=(2,20)
            
    #         run_hc(ivecs_names, ivecs, data_dirs, label, prange, out_fig, style_list=style_list, legend_loc = 'auto')
            
            
    # #----------------------------
    # #------- SPK ---------------
    
    # for lang in ['fin', 'ger']:
    #     for t_type in ['bil', 'mono']:
    #         # -----------------------------------------------------------------------------------------------------------------------------------------------------------------
    #         #### Create Test plots per lang - ENG-GER
    #         ivecs_names=['mono_eng_native', 'mono_eng','mono_{}'.format(lang),'mix_spkmatch_eng-{}'.format(lang), 'bil_eng-{}'.format(lang)]
    #         ivecs_test_name='test_eng-{}-{}'.format(lang,t_type)
    #         ivecs=['exp_emime/ivectors-deltassdc/ivectors_128_tr-train_{}_ts-{}/ivector.scp'.format(n, ivecs_test_name) for n in ivecs_names]                                                                       
    #         data_dirs=['data/emime/{}'.format(ivecs_test_name)]*len(ivecs_names)     
    #         style_list=[('g','-'), ('g', '--'), ('g', '-.'),('r', ':'), ('b',':')]
    #         label='spk'
    #         out_fig='figs/hc/emime-deltassdc/hc_test_{}_spk_eng-{}.pdf'.format(t_type, lang)
    #         if t_type == 'bil':
    #             prange=(2,20)
    #         else:
    #             prange=(4,20)
                
    #         run_hc(ivecs_names, ivecs, data_dirs, label, prange, out_fig, style_list=style_list, legend_loc = 'auto')
