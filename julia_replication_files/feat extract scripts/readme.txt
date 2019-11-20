This folder contains all the scripts required for the feature extraction
pipeline used in Carbajal et al.'s (2016) CogSci paper.

The pipeline is divided in two stages:

1) The first stage is run in Oberon as it requires HTK and Kaldi.
	The script is called extract_mfcc_and_f0.sh - The outputs are
	two separate folders containing feature files in htk format,
	one with MFCCs and the other one with F0.
2) The second stage is run in Matlab (I do it locally in Windows).
	The script is called pipeline_SDC.m - The outputs are two separate
	folders containing features files in htk format, one with the
	concatenated features MFCC-F0, and the other one the MFCC-F0-SDCs.

The folder also contains the HTK config file used for MFCC extraction.