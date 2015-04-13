
% This script uses the the DEAP data set to create a emotion classifier.
% this data set consists of experiments where various music videos were
% shown to users to evoke a particular emotion and EEG along with other
% biological signals were recorded. An SVM classifier is suggested for use
% in this.

%%
% v2 uses spectrogram vs bandpower to get spectral information. The
% difference is that bandpower returns a scalar value while spectrogram
% returns a qualitative number. 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                              UPDATE LOG
% 4/7/2015 CURRENT STATE
%   Currently this script will read in two csv files (data and lables) and
%   extrace time windowed features from the signal. The goal of this script
%   is to find what features will be most valuable to extract for the
%   model. Features implemetned are from IEEE paper from singapor
%   university
% TO DO:   
% ---run through all participants and caluculate the average corrolation
% for each feature. Then plot in colormap to see the result. Also find the
% average mean and std for each feature to plot in an error 
%
% ----Implement Combination features (spectral features specifically)
% & possibly fractal features if you can figure out how to do it in a way
% that is transferable easily to python.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Create Paths
clear all; close all; clc;
addpath(genpath('C:\Users\Jared\Documents\ESE519\Final Project\metadata_xls'))
addpath(genpath('C:\Users\Jared\Dropbox\DEAPdatasets\Preprocessed_csv'))
addpath(genpath('C:\Users\Jared\Documents\GitHub\ese519-project-spring2015\code\MATLAB\select_features'))
addpath(genpath('lib'))

%%%%%%%%%%%%%%%%%%%%%% HELPFUL INFORMATION  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Channel Legend
% Frontal Lobe
% F4 - 27
% F7 - 3
% FC5 - 6
% AF3 - 2

% Temporal Lobe
% T8 - 24
% T7 - 7

% Occipital Lobe
% P7 - 11
% P8 - 20

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
% Initialize 

ch = [27 3 6 2 24 7 11 20];
    
%meta data
fs = 128;
%Bands of interest
alpha = [10 12];
sAlpha = [8 10];
beta = [12 27];
gamma = [27 45];
theta = [3 8];
delta = [0.2 3];

freqBands = [ alpha;
               sAlpha;
                beta;
                gamma;
                theta;
                delta]; % in Hz

fRange = [alpha sAlpha beta gamma theta delta];

songLen = 8064;

allCorr = cell(32,1);
for pt = 1:32
    
    if(pt < 10)
    curData =  sprintf('s0%dDatav2.csv',pt);
    curLab =  sprintf('s0%dLabels.csv',pt);
    else
    curData =  sprintf('s%dDatav2.csv',pt);
    curLab =  sprintf('s%dLabels.csv',pt);
    end

    data = load(curData);

    %file formated super weird.... you have to do this in order to format it
    %correctly

    x = data(ch,:);

    winLen = 4;
    winDisp = 1;

    %Use Num Wins anoyn func
    NumWins = @(xLen,fs,winLen,winDisp) round((xLen-(winLen - winDisp)*fs)/(winDisp*fs));

    %Find number of windows
    windows = NumWins(length(x), fs, winLen, winDisp);
    dispSamp = winDisp*fs;  %Disp in terms of samples

    %%
    % Feature extraction 
    % BETTER WAY using spectrogram vs band power
    %test
    % [chSpect, freqBins] = spectrogram(x(2,:),winLen,winLen-winDisp,1024,fs);

    F = [];
    asymFeats = zeros(windows,(size(freqBands,1)*3)+3);

    for i = 1:length(ch)
        %%%%%Another Way to do this ^%%%%
        %Spectral Features
        [chSpect, freqBins] = spectrogram(x(i,:),winLen*fs,(winLen-winDisp)*fs,1024,fs);

        % construct freq-domain feats
        freqFeats = zeros(size(freqBands,1),size(chSpect,2));
        for j = 1:size(freqFeats)
           bandInds = freqBins >= freqBands(j,1) & freqBins <= freqBands(j,2);
           freqFeats(j,:) = mean(abs(chSpect(bandInds,:)),1);
           %freqFeats(i,:) = log(sum(abs(chSpect(bandInds,:)),1)+1);
        end

    C = conv(x(i,:),ones(1,winLen*fs)/(winLen*fs),'valid');
    timeavg_bin = C(1:(winDisp)*fs:end)';

    %F,T,O (Frontal, Temporal, and Occipital assymetry index)
    %kept addition row of zeros so could be formated into grid
    if i == 2  
        asymFeats(:,1:6) = (freqFeats' - F(:,end-6:end-1))./(freqFeats' + F(:,end-6:end-1));
    elseif i == 6
        asymFeats(:,8:13) = (freqFeats' - F(:,end-6:end-1))./(freqFeats' + F(:,end-6:end-1));
    elseif i == 8
        asymFeats(:,15:20) = (freqFeats' - F(:,end-6:end-1))./(freqFeats' + F(:,end-6:end-1));
    end
    
    %make feature matrix
    F = [F freqFeats' timeavg_bin];

    fprintf('%d',i)   
    end
    
    F = [F asymFeats];
    
    % Create Labels
    lab = load(curLab);

    vaLab = lab(:,1:4);
    %normalize scale to be centered around 0;
    vaLab = (vaLab - 5)';

    numInterp = 63;
    vaLab2(:,1) = reshape(repmat(vaLab(1,:),numInterp,1),length(vaLab(1,:))*numInterp,1);
    vaLab2(:,2) = reshape(repmat(vaLab(2,:),numInterp,1),length(vaLab(2,:))*numInterp,1);
    vaLab2(:,3) = reshape(repmat(vaLab(3,:),numInterp,1),length(vaLab(3,:))*numInterp,1);
    vaLab2(:,4) = reshape(repmat(vaLab(4,:),numInterp,1),length(vaLab(4,:))*numInterp,1);

    %%
    % We actually don't want to normalize because we want to find the
    % difference between baseline and non baseline
    % %NORMALIZE
    featAV(:,pt)  = mean(F,1);
    featSTD(:,pt) = std(F,1);
%   figure(1)
%   errorbar(featAV,featSTD)

    
    for i = 1:size(featAV,2)
        F(:,i) = (F(:,i) - featAV(i,pt)) ./featSTD(i,pt);
    end


    %find feature corr and plot in meaningful way
    featCor = corr(F,vaLab2(1:size(F,1),:),'type','Spearman');
    valCor(:,pt) = featCor(:,1);
    arCor(:,pt) = featCor(:,2);
    domCor(:,pt) = featCor(:,3);
    likeCor(:,pt) = featCor(:,4);


%     valCor = featCor(:,1);
%     valCor = reshape(valCor,length(ch),size(F,2)/length(ch));
%     figure(33)
%     imagesc(valCor);
%     colorbar;
%     xlabel('Feat')
%     ylabel('Channel')
% 
%     arCor = featCor(:,2);
%     arCor = reshape(arCor,length(ch),size(F,2)/length(ch));
%     figure(34)
%     imagesc(arCor);
%     colorbar;
%     xlabel('Feat')
%     ylabel('Channel')

    %Reshape feature into two matrices: Baseline - Target (last 30s of clip)
    %BASELINE
    %get the average features for the first 3 seconds of each clip (baseline)
    % baseF = mean(F(mod(1:size(F,1),63)<=4&mod(1:size(F,1),63)>0,:),1);

    %TARGET STIM TIME
    % stimF = F(mod(1:size(F,1),63)>=33,:);

    %normalize so that basline eeg components is removed from stim
    % for i = 1:length(baseF)
    % stimF(:,i) = stimF(:,i) - baseF(i);
    % end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %Create labels
    %Using a 4 emotion classification system:
    %               -1 -> Happy   (V > 0; A > 0)
    %               -2 -> Angry   (V < 0; A > 0)
    %               -3 -> Sad     (V < 0; A < 0)
    %               -4 -> Relaxed (V > 0; A < 0)
    %

    %emot contains lables 1-4 vs scalar values for arousal and valence
    emot = zeros(size(vaLab2,1),1);
    emot(vaLab2(:,1) > 0 & vaLab2(:,2) > 0) = 1;
    emot(vaLab2(:,1) < 0 & vaLab2(:,2) > 0) = 2;
    emot(vaLab2(:,1) < 0 & vaLab2(:,2) < 0) = 3;
    emot(vaLab2(:,1) > 0 & vaLab2(:,2) < 0) = 4;


end



    valCor = mean(valCor,2);
    valCor = reshape(valCor,length(ch)+3,size(F,2)/(length(ch)+3));
    figure(1)
    imagesc(valCor);
    colorbar;
    title('Valence Correlation')
    xlabel('Features') 
    ylabel('1-8 Channels/9-11 Asymmetry Index')    

    
    arCor = mean(arCor,2);
    arCor = reshape(arCor,length(ch)+3,size(F,2)/(length(ch)+3));
    figure(2)
    imagesc(arCor);
    colorbar;
    title('Arousal Correlation')
    xlabel('Features')
    ylabel('1-8 Channels/9-11 Asymmetry Index')    
    
    domCor = mean(domCor,2);
    domCor = reshape(domCor,length(ch)+3,size(F,2)/(length(ch)+3));
    figure(3)
    imagesc(domCor);
    colorbar;
    title('Dominance Correlation')
    xlabel('Features')
    ylabel('1-8 Channels/9-11 Asymmetry Index')    
    
    likeCor = mean(likeCor,2);
    likeCor = reshape(likeCor,length(ch)+3,size(F,2)/(length(ch)+3));
    figure(4)
    imagesc(likeCor);
    colorbar;
    title('Liking Correlation')
    xlabel('Features')
    ylabel('1-8 Channels/9-11 Asymmetry Index')    
    
    






