% Before running, go to directory that contains the MFCC feature files

clear all

dirname = 'wavs';

cd([dirname '_MFCC']) % Change directory to MFCC file dir

mkdir(['../' dirname '_MFCCF0']) % Make output dir for MFCC+F0 feature files

fnames = dir('*.htk');
numfids = length(fnames);


for fileid = 1:numfids
    
    MFCC_file = fnames(fileid).name;
    name = strsplit(MFCC_file,'.');
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
         
        
    writehtk(['../' dirname '_MFCCF0/MFCCF0_',MFCC_file],mfcc_f0',fp,9); % Save in new htk file
    
    clear MFCC_file F0_file d d2 fp fp2 dt dt2 tc tc2 t t2
end

cd ..