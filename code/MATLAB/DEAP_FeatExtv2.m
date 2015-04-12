%%
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
alpha = [8 12];
beta = [12 27];
gamma = [27 45];
theta = [3 8];
delta = [0.2 3];

freqBands = [ alpha;
                beta;
                gamma;
                theta;
                delta]; % in Hz

fRange = [alpha beta gamma theta delta];

songLen = 8064;

data = load('s03Datav2.csv');

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

%make feature matrix
F = [F freqFeats' timeavg_bin];

fprintf('%d',i)   
        
end


% Create Labels
lab = load('s03Labels.csv');


vaLab = lab(:,1:2);
%normalize scale to be centered around 0;
vaLab = (vaLab - 5)';

numInterp = 63;
vaLab2(:,1) = reshape(repmat(vaLab(1,:),numInterp,1),length(vaLab(1,:))*numInterp,1);
vaLab2(:,2) = reshape(repmat(vaLab(2,:),numInterp,1),length(vaLab(2,:))*numInterp,1);

%%
% We actually don't want to normalize because we want to find the
% difference between baseline and non baseline
% %NORMALIZE
featAV  = mean(F,1);
featSTD = std(F,1);
figure(1)
errorbar(featAV,featSTD)

for i = 1:size(featAV,2)
    F(:,i) = (F(:,i) - featAV(i)) ./featSTD(i);
end


%find feature corr and plot in meaningful way
featCor = corr(F,vaLab2(1:size(F,1),:));

valCor = featCor(:,1);
valCor = reshape(valCor,length(ch),size(F,2)/length(ch));
figure(33)
imagesc(valCor);
colorbar;
xlabel('Feat')
ylabel('Channel')

arCor = featCor(:,2);
arCor = reshape(arCor,length(ch),size(F,2)/length(ch));
figure(34)
imagesc(arCor);
colorbar;
xlabel('Feat')
ylabel('Channel')


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

%For possible regression model
R = [ones(size(F,1),1) F];

%assign test and train set
train = 1:(63*25);
test =  (train(end)+1):train(end)+63*14;

fTrain = F(train,:);
fTest = F(test,:);

vaTrain = vaLab2(train,:);
vaTest =  vaLab2(test,:);

 


%%
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

emotTr = emot(train);
emotTest = emot(test);


%do pca anlysis
[coef, score, latent] = pca(fTrain);

%use top two principal components
pcOne = score(:,1);
pcTwo = score(:,2);

%plot two components to show seperations
figure(8)
plot3(pcOne,pcTwo,score(:,3),'.');
xlabel('Principal Component One')
ylabel('Principal Component Two')
title('Spike Waveforms Scatter Plot Represented by Top Two Principal Components')

%%
% b. Variance Explained by Principle Components

%%
% The top two principle components represent or "explain" 73.85% of the
% variance. 

%Show explained variance as a function of each principal component
figure(9)
plot((latent./sum(latent(:)))*100, 'bo')
xlim([0 63])
xlabel('Principal Component')
ylabel('Variance Explained (%)')
title('Principal Component vs. Total Variance Explained')
explVar = sum(latent(1:2))/sum(latent(:))


%K-nn classify

kTr = knnclassify(fTrain,fTrain,emotTr,4);

kTest = knnclassify(fTest,fTrain,emotTr,4);

%calculate Training error
error = sum(kTr ~= emotTr);
trainErrorKnn = (error/length(emotTr))*100
%Train Error 0 percent

%calculate Training error
error = sum(kTest ~= emotTest);
testErrorKnn = (error/length(emotTest))*100
%Train Error 0 percent



%%%%%%%%%%%%%%%%%%%%%%  REGRESSION  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%%Regression I don't think this is a good idea
%%%%%%%%%%%%%%%%%%%%%%%%%%%  TRAIN MODEL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% w = mldivide((rTrain'*rTrain),(rTrain'*vaTrain));
% 
% 
% %predict
% 
% u = rTrain*w;












