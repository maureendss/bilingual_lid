% This script reads all .htk files in the current folder, extracts SDC
% features and saves a new .htk file with a concatenation of MFCC + SDC.

% IMPORTANT: Check the dimensions of the feature matrix 'd' before using.
% The correct dimensions are row=features, column=frames.

% The funciton sdc.m takes as first parameter the number of features it
% will use for sdc calculation, if using F0 it should be 8, otherwise 7
% (this number includes C0 which should be at the end of the feature
% matrix, and the N-1=6 first cepstral coefficients).

clear all

cd('wavs_MFCCF0')

minlength = 40; % Minimum file length (in frames) - I used 40 for CID and 200 for BILING
withF0     = 1; % If not using F0, change this value to 0.
Ncepscoeff = 7; % This includes C0 and the first N-1 cepstral coeffs.



fnames = dir('*.htk');
numfids = length(fnames);

currentdir = pwd;
[upperpath,deepestfolder,~] = fileparts(currentdir);
mkdir(['../' deepestfolder 'SDC'])



% Check which dimension represents the features:
% For this, we read the first two files and find the common dimension.
% If the first dimension agrees, do nothing. If it's the 2nd dimension,
% we will flip the matrix.
d1 = readhtk(fnames(1).name);
d2 = readhtk(fnames(2).name);

if size(d1,1)==size(d2,1)
    flipmatrix = 0;
elseif size(d1,2)==size(d2,2)
    flipmatrix = 1;
end


% Read all files and calculate SDC features
for fileid = 1:numfids
    
    htk_file = fnames(fileid).name;
    [d,fp,dt,tc,t] = readhtk(htk_file); % Read htk file
    
    if flipmatrix
        d = d';
    end
    
    if size(d,2) > minlength    % Set a minimum length of file (in frames)
        mfcc_sdc = sdc(d,Ncepscoeff+withF0,1,3,7);         % Add SDC features
        writehtk(['../' deepestfolder 'SDC/SDC_',htk_file],mfcc_sdc',fp,9); % Save in new htk file
    end
    
    imagesc(d)
    clear htk_file d fp dt tc t
end

cd ..