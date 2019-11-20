clc
clear

%% Step0: Opening MATLAB pool
nworkers = 2;
nworkers = min(nworkers, feature('NumCores'));
isopen = matlabpool('size')>0;
if ~isopen, matlabpool(nworkers); end

%% Step1: Training the UBM
dataList = 'segmented_s02_list.txt';
nmix        = 256;
final_niter = 30;
ds_factor   = 1;
ubm = gmm_em(dataList, nmix, final_niter, ds_factor, nworkers);

%% Step2: Learning the total variability subspace from background data
tv_dim = 200; 
niter  = 5;
dataList = 'segmented_s02_list.txt';
fid = fopen(dataList, 'rt');
C = textscan(fid, '%s');
fclose(fid);
feaFiles = C{1};

% Calculate sufficient statistics (stats) for each speaker x utterance
stats = cell(length(feaFiles), 1);
parfor file = 1 : length(feaFiles),
    [N, F] = compute_bw_stats(feaFiles{file}, ubm);
    stats{file} = [N; F];
end

T = train_tv_space(stats, ubm, tv_dim, niter, nworkers);

% Save it!
save('UBM_TV_buckeye02')