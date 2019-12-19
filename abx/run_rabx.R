#!/usr/bin/env Rscript

#install.packages("proxy");
source("/home/mde/repos/rabx/rABX/R/rABX_filter.R");
#source("/home/mde/repos/rabx/rABX/R/rABX_base.R");

args = commandArgs(trailingOnly=TRUE)
abx_dir=args[1]

print(abx_dir)

item_file=paste(abx_dir,"/ivectors.item",sep = "")
ivectors_file=paste(abx_dir,"/ivectors.csv",sep = "")

#item_file="/scratch2/mde/projects/lid/local/kaldi_setup/exp/ivectors/ivectors_128_tr-train_english_ts-test/ivectors.item"
#ivectors_file="/scratch2/mde/projects/lid/local/kaldi_setup/exp/ivectors/ivectors_128_tr-train_english_ts-test/ivector.csv"

item_dataset <- read.table(file = item_file, sep = ' ', header = FALSE)
colnames(item_dataset) <- c("ID", "onset", "offset", "lang", "spk")
ivectors_dataset <- read.table(file = ivectors_file,sep = ',', header = FALSE)
colnames(ivectors_dataset) <- c("ID",sprintf("v%02d", seq(1,ncol(ivectors_dataset)-1)))
D <- merge(item_dataset,ivectors_dataset, by="ID")
values_colnames <- colnames(D)[6:ncol(D)]

abx_df_cos <- abx.df(D,data=values_colnames,on="lang",method="cosine")
abx_df_cos_MEAN = weighted.mean(abx_df_cos["ABX_cosine"],abx_df_cos["num_triplets"] )

#abx_df_cos_across <- abx.df(D,data=values_colnames,on="lang",across="spk",method="cosine")

abx_df_cos_filter <- abx.df(D,data=values_colnames,on="lang",filter="spk",method="cosine")
abx_df_cos_filter_MEAN = weighted.mean(abx_df_cos_filter["ABX_cosine"],abx_df_cos_filter["num_triplets"] )

write.csv(abx_df_cos, file = paste(abx_dir,"/rabx.csv",sep = ""))
write.table(abx_df_cos_MEAN, paste(abx_dir,"/rabx.avg",sep = ""), row.names = FALSE, col.names = FALSE)
write.csv(abx_df_cos_filter, file = paste(abx_dir,"/rabx_filter.csv",sep = ""))
write.table(abx_df_cos_filter_MEAN, paste(abx_dir,"/rabx_filter.avg",sep = ""), row.names = FALSE, col.names = FALSE)
