import numpy as np
import kaldiio
import pandas as pd
from sklearn import linear_model
from scipy import stats
from sklearn import metrics

#just notes on log reg. Not to be run as is.


with open('data/emime/train_bil_eng-ger/utt2lang', 'r') as input_utt2lang:
    utt2lang_dict={}
    for line in input_utt2lang:
        utt2lang_dict[line.split(' ')[0]] = line.split(' ')[1].strip('\n')


ivec='exp_emime/ivectors-deltassdc/ivectors_128_tr-train_bil_eng-ger_ts-train_bil_eng-ger/ivector.scp'

with kaldiio.ReadHelper('scp:'+ivec) as reader:
    ivectors={}
    for k, iv in reader:
        ivectors[k]=iv


#ivectors_df = pd.DataFrame.from_dict(ivectors)
ivectors_df = pd.DataFrame.from_dict(ivectors, orient='index') #this is our y

#utt2lang_df = pd.DataFrame(utt2lang_dict, index=["lang"])
predictor_df = pd.DataFrame.from_dict(utt2lang_dict, orient='index', columns=["lang"], dtype="category") #cat is so can do dummy encoding
predictor_df["lang_dich"] = predictor_df["lang"].cat.codes #change dichotomous

with open('data/emime/train_bil_eng-ger/utt2spk', 'r') as input_utt2spk:
    utt2spk_dict={}
    for line in input_utt2spk:
        utt2spk_dict[line.split(' ')[0]] = line.split(' ')[1].strip('\n')
predictor_df["spk"] = pd.DataFrame.from_dict(utt2spk_dict, orient='index',  dtype="category")
predictor_df = pd.concat([predictor_df, pd.get_dummies(predictor_df["spk"], prefix='spk')], axis=1)  #get one hot dummies


# with open('data/emime/train_bil_eng-ger/utt2sent', 'r') as input_utt2sent:
#     utt2sent_dict={}
#     for line in input_utt2sent:
#         utt2sent_dict[line.split(' ')[0]] = line.split(' ')[1].strip('\n')
# predictor_df["sent"] = pd.DataFrame.from_dict(utt2sent_dict, orient='index',  dtype="category")
# predictor_df = pd.concat([predictor_df, pd.get_dummies(predictor_df["sent"], prefix='sent')], axis=1)  #get one hot dummies
#





spk_var = predictor_df[predictor_df.columns[predictor_df.columns.str.contains('spk_')]]
#df = pd.concat([utt2lang_df, ivectors_df])
lang_var=predictor_df["lang_dich"]

X_lang = np.reshape(np.array(predictor_df["lang_dich"]), (-1,1))
X_lang_z = (X_lang - np.min(X_lang))/np.ptp(X_lang) #useless cause between 0 and 1 but well - at least works for other predictors


y = ivectors_df
#X_spk = np.reshape(np.array(predictor_df["lang_dich"])
X_spk = predictor_df[predictor_df.columns[predictor_df.columns.str.contains('spk_')]]
X_spk_z = X_spk.select_dtypes(include=[np.number]).dropna().apply(stats.zscore)
X_lang_z = (X_lang - np.min(X_lang))/np.ptp(X_lang) #useless cause between 0 and 1 but well - at least works for other predictors




lm_lang = linear_model.LinearRegression()
model_lang = lm_lang.fit(X_lang,y)
r2_lang = lm_lang.score(X_lang,y)

lm_spk = linear_model.LinearRegression()
model_spk = lm_spk.fit(X_spk,y)
r2_spk = lm_spk.score(X_spk,y)


#(no need to normalise the data - will get the same) - ?

lm_spk = linear_model.LinearRegression()
model_spk = lm_spk.fit(X_spk,y)
r2_spk = lm_spk.score(X_spk,y)








# #also get adjusted r square see below
# yhat = model.predict(X)
# SS_Residual = sum((y-yhat)**2)
# SS_Total = sum((y-np.mean(y))**2)
# r_squared = 1 - (float(SS_Residual))/SS_Total
# adjusted_r_squared = 1 - (1-r_squared)*(len(y)-1)/(len(y)-X.shape[1]-1)
# print r_squared, adjusted_r_squared




#X_mult = pd.concat([predictor_df["lang_dich"], predictor_df[ predictor_df.columns[predictor_df.columns.str.contains('spk_')]]], axis=1)
X_mult=pd.concat([lang_var, spk_var], axis=1)
lm_mult = linear_model.LinearRegression()
model_mult = lm_mult.fit(X_mult,y)
r2_mult = lm_mult.score(X_mult,y)
# What is coeff? Does it make sense to all put together???
coeffs_mult = pd.DataFrame(np.transpose(lm_mult.coef_), index=X_mult.columns)


#MAYBE BETTER??? NEED STANDARDIZED COEFFICIENTS
import statsmodels.api as sm
from scipy import stats


X2 = sm.add_constant(X_mult)
est = sm.OLS(y[0], X2) #!! NEED TO DO FOR EACH IVECTOR VALUE!
est2 = est.fit()
print(est2.summary())
#USE ANOVA???
#https://stackoverflow.com/questions/27928275/find-p-value-significance-in-scikit-learn-linearregression

#Just compare r sqaures?


https://stackoverflow.com/questions/50842397/how-to-get-standardised-beta-coefficients-for-multiple-linear-regression-using
X_mult_z = X_mult.select_dtypes(include=[np.number]).dropna().apply(stats.zscore)

# fitting regression
#formula = 'y ~ x1 + x2 + x3'
#result = smf.ols(formula, data=X_mult_z).fit()
X2_z = sm.add_constant(X_mult_z)
est_z = sm.OLS(y[0], X2_z) #!! NEED TO DO FOR EACH IVECTOR VALUE!
est2_z = est.fit()
print(est2_z.summary()) #just gives same

# checking results
result.summary()
