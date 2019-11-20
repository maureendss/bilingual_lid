% This script takes MFCCs and F0 files and concatenates them. Then it 
% calculates SDC features based on the new files. It is based on two scripts
% from the Brno team (BUT): add_F0_to_MFCC.m and add_SDC_to_MFCC.m

% READ THIS BEFORE RUNNING:
% 1) Before running, go to directory that contains the features folders
% 2) Some parameters need to be defined for the sdc function (see 2nd STEP)
% 3) This script will automatically generate the file list in a txt inside
% the SDC output folder that can be used to feed it into MSR-IT.

%% FIRST STEP: add Kaldi's F0 to HTK's MFCCs (from add_F0_to_MFCC.m)

clear all

%language = 'bresilien';
dirname = 'wav';
%cd(language) % Change directory to each language folder
cd([dirname '_MFCC']) % Change directory to MFCC file dir

mkdir(['../' dirname '_MFCCF0']) % Make output dir for MFCC+F0 feature files

fnames = dir('*.htk');
numfids = length(fnames);


for fileid = 1:numfids
    
    MFCC_file = fnames(fileid).name;
    name = strsplit(MFCC_file,'.htk'); %strsplit(MFCC_file,'.');
    F0_file = ['../' dirname '_F0/' name{1} '.kf0.fea'];
    
    [d,fp,dt,tc,t] = readhtk(MFCC_file);    % Read htk MFCC file
    [d2,fp2,dt2,tc2,t2] = readhtk(F0_file); % Read kaldi F0 file
    
    if size(d,1) == size(d2,1)
        mfcc_f0 = [d2(:,2) d];              % Concatenate F0 with MFCC (F0 will be the first column)
    elseif size(d,1) < size(d2,1)
        mfcc_f0 = [d2([1:size(d,1)],2) d];
    elseif size(d,1) > size(d2,1)
        mfcc_f0 = [d2(:,2) d([1:size(d2,1)],:)];
    end
    
    % Uncomment this to visualize the MFCCs: (don't use if there's 10+ files!)
    %figure; imagesc(mfcc_f0')   
        
    writehtk(['../' dirname '_MFCCF0/MFCCF0_',MFCC_file],mfcc_f0',fp,9); % Save in new htk file
    
    clear MFCC_file F0_file d d2 fp fp2 dt dt2 tc tc2 t t2
end

cd ..

% SECOND STEP: Calculate SDC features (from add_SDC_to_MFCC.m)

% This script reads all .htk files in the current folder, extracts SDC
% features and saves a new .htk file with a concatenation of MFCC + SDC.

% IMPORTANT: Check the dimensions of the feature matrix 'd' before using.
% The correct dimensions are row=features, column=frames.

% The funciton sdc.m takes as first parameter the number of features it
% will use for sdc calculation, if using F0 it should be 8, otherwise 7
% (this number includes C0 which should be at the end of the feature
% matrix, and the N-1=6 first cepstral coefficients).

cd([dirname '_MFCCF0'])

minlength = 1;%40; % Minimum file length (in frames) - I used 40 for CID and 200 for BILING
withF0     = 1; % If not using F0, change this value to 0.
Ncepscoeff = 7; % This includes C0 and the first N-1 cepstral coeffs.

fnames = dir('*.htk');
numfids = length(fnames);

currentdir = pwd;
[upperpath,deepestfolder,~] = fileparts(currentdir);
mkdir(['../' deepestfolder 'SDC'])
fid = fopen(['../' deepestfolder 'SDC/' dirname '_list.txt'], 'w');

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
    
    % Print names of files to a list:
    fprintf(fid,'%s\n',['SDC_' htk_file]);
    
    clear htk_file d fp dt tc t
end

fclose(fid);
cd .. %../.. 