%% Extracting test i-vectors

clear all
% Note: Before running, load the ubm structure and the T matrix.
load('ubm_and_TV/UBM_TV_buckeye02.mat','ubm','T','tv_dim');

% Language pair:
langs = {'nl','en'};
% Location of feature files:
filesdir = ['feature_files/wav_' langs{1} '_16kHz_MFCCF0SDC'];

% Output location to drop i-vectors:
for i = 1:2
    outputname = ['wav_' langs{1} '_ivectors_' langs{i}];
    outputdir = ['test_ivectors_buckeyeubm/' outputname];

    % File list to process (located in outputdir):
    dataList = [outputname '_list.txt'];

    fid = fopen([outputdir '/' dataList], 'rt');
    C = textscan(fid, '%s %s');
    fclose(fid);

    cd(filesdir)
    feaFiles = C{1};
    test_ivs = zeros(tv_dim, length(feaFiles));

    % First, Calculate sufficient statistics (stats) for each utterance
    stats = cell(length(feaFiles), 1);
    parfor file = 1 : length(feaFiles),
        [N, F] = compute_bw_stats(feaFiles{file}, ubm);
        stats{file} = [N; F];
    end

    % For each utterance in the list, extract one IV:
    parfor file = 1 : length(feaFiles),
        test_ivs(:, file) = extract_ivector(stats{file}, ubm, T);
    end

    cd ../..

    save([outputdir '/' outputname '_buckeye02'], 'test_ivs');
    clear C file feaFiles fid test_ivs stats
end