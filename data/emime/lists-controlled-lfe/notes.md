# Lists.

We are using the original LID Train sets as test sets for the LFE experiments (as they require multiple speakers).  
### English - Finnish

We reduced the sets by -1) removing all utterances which id finished by "_0", removing all utterances which ID number wasn't ending by 0 or 5 .

**Bilingual** : lfe-test_bil_eng-fin.txt
**Mixed** : lfe-test_mix_eng-fin.txt + train_mix_2_eng-fin.txt
**Monolingual** : lfe-test_mono_fin.txt + lfe-test_mono_eng_finspk.txt + lfe-test_eng_native.txt


### English - German

**Bilingual** : train_bil_1_eng-ger.txt + train_bil_2_eng-ger.txt
**Mixed** : train_mix_1_eng-ger.txt + train_mix_2_eng-ger.txt
**Monolingual** : train_mono_ger.txt + train_mono_eng_gerspk.txt + train_mono_eng_native.txt


---

## Test sets

### English - Finnish

**Bilingual** : test_eng-fin-bil.txt
**Mixed** : test_eng-fin-mixed.txt *(Not used)*
**Monolingual** : test_eng-fin-mono.txt *(Not used)*
