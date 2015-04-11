%%
% This script uses the the DEAP data set to create a emotion classifier.
% this data set consists of experiments where various music videos were
% shown to users to evoke a particular emotion and EEG along with other
% biological signals were recorded. An SVM classifier is suggested for use
% in this.

%IMPORTANT: DATA FORMAT!!!!!!
 %Each row in the data.csv files corrosponds to the trial. So in order to
 %get it into the right format you must extract that row then reshape it.
 %We may need to write a script to reshape these .csv files in order to
 %accomodate this.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                              UPDATE LOG
% 4/7/2015 CURRENT STATE
%   Currently this script will read in two csv files (data and lables) and
%   extrace time windowed features from the signal. The goal of this script
%   is to find what features will be most valuable to extract for the
%   model. Features implemetned are from IEEE paper from singapor
%   university
% TO DO:   Implement Combination features (spectral features specifically)
% & possibly fractal features if you can figure out how to do it in a way
% that is transferable easily to python.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


clear all; close all; clc;
addpath(genpath('C:\Users\Jared\Documents\ESE519\Final Project\metadata_xls'))
addpath(genpath('C:\Users\Jared\Documents\ESE519\Final Project\data_preprocessed_matlab'))
addpath(genpath('C:\Users\Jared\Dropbox\DEAPdatasets\Preprocessed_csv'))
addpath(genpath('BrainWAV'))
addpath(genpath('lib'))


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

ch = [27 3 6 2 24 7 11 20];
    
%meta data
fs = 128;
%Bands of interest
alpha = [8; 12];
beta = [12; 27];
gamma = [27; 45];
theta = [3 ;8];
delta = [0.2; 3];

fRange = [alpha beta gamma theta delta];

songLen = 8064;

data = load('s01Datav2.csv');

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

%initialize of array
Win = zeros(winLen*fs,windows)';
alphaP =  zeros(length(ch),windows); %compute featFn for each window
betaP =   zeros(length(ch),windows);
gammaP =  zeros(length(ch),windows);
thetaP =  zeros(length(ch),windows);
% deltaP =  zeros(length(ch),windows);

%
chAvg =  zeros(length(ch),windows);
chDev =  zeros(length(ch),windows);
totAvg = zeros(windows,1);
totDev = zeros(windows,1);

%reshape matrix into rows of windows and calc. feature for each row 

%Calculate moving window features 
for i=1:windows
    %Do this for each channel
    for j = 1:size(x,1)
        %Get current window 
        Win(i,:) = x(j,(i-1)*dispSamp + 1:(i-1)*dispSamp + winLen*fs);
        %%%%%%%%%%Time based features%%%%%%%%%%%%%%%%%%%%%
        chAvg(j,i) = mean(Win(i,:));
        chDev(j,i) = std(Win(i,:));
        %%%%%%%%%%%spectral features%%%%%%%%%%%%
        alphaP(j,i) = bandpower(Win(i,:),fs,alpha);
        betaP(j,i) = bandpower(Win(i,:),fs,beta);
        gammaP(j,i) = bandpower(Win(i,:),fs,gamma); 
        thetaP(j,i) = bandpower(Win(i,:),fs,theta); 
%       deltaP(j,i) = bandpower(Win(i,:),fs,delta);  %This is really filtered out
    end
%%%%%%%%%%%%%%%Computed combination features%%%%%%%%%%%%%%%
    totAvg(i) = mean(chAvg(:,i),1);
    totDev(i) = std(chDev(:,i),1);
end


%Create Feature matrix:

%features to be extracted from each channel

%all
fv1 = [alphaP(1,:)' betaP(1,:)' gammaP(1,:)' thetaP(1,:)'];
fv2 = [alphaP(2,:)' betaP(2,:)' gammaP(2,:)' thetaP(2,:)'];
fv3 = [alphaP(3,:)' betaP(3,:)' gammaP(3,:)' thetaP(3,:)'];
fv4 = [alphaP(4,:)' betaP(4,:)' gammaP(4,:)' thetaP(4,:)'];
fv5 = [alphaP(5,:)' betaP(5,:)' gammaP(5,:)' thetaP(5,:)'];
fv6 = [alphaP(6,:)' betaP(6,:)' gammaP(6,:)' thetaP(6,:)'];
fv7 = [alphaP(7,:)' betaP(7,:)' gammaP(7,:)' thetaP(7,:)'];
fv8 = [alphaP(8,:)' betaP(8,:)' gammaP(8,:)' thetaP(8,:)'];
fvComb1 = [totAvg totDev];

% %selected
% fv1 = [betaP(1,:)'  ];
% fv2 = [betaP(2,:)' alphaP(2,:)'];
% fv3 = [betaP(3,:)'];
% fv4 = [betaP(4,:)' alphaP(4,:)'];
% fv5 = [thetaP(5,:)' gammaP(5,:)'];
% fv6 = [thetaP(6,:)' gammaP(6,:)'];
% fv7 = [alphaP(7,:)' gammaP(7,:)'];
% fv8 = [alphaP(8,:)' gammaP(8,:)'];
% fvComb1 = [totAvg totDev];


%Final feature matrix
FV = [fv1 fv2 fv3 fv4 fv5 fv6 fv7 fv8];
% FV = [fv1 fv2 fv3 fv4];


lab = load('s01Labels.csv');

vaLab = lab(:,1:2);
%normalize scale to be centered around 0;
vaLab = (vaLab - 5)';

numInterp = 63;
vaLab2(:,1) = reshape(repmat(vaLab(1,:),numInterp,1),length(vaLab(1,:))*numInterp,1);
vaLab2(:,2) = reshape(repmat(vaLab(2,:),numInterp,1),length(vaLab(2,:))*numInterp,1);

%%
%NORMALIZE
featAV  = mean(FV,1);
featSTD = std(FV,1);
figure(1)
errorbar(featAV,featSTD)


for i = 1:size(featAV,2)
    FV(:,i) = (FV(:,i) - featAV(i)) ./featSTD(i);
end

R = [ones(size(fv1,1),1) FV];


%assign test and train set
train = 1:(63*25);
test =  (train(end)+1):train(end)+63*14;

rTrain = FV(train,:);
rTest = FV(test,:);

vaTrain = vaLab2(train,:);
vaTest =  vaLab2(test,:);


%%%%%%%%%%%%%%%%%%%%%%%%%% CLASSIFY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%SVM model for class


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
[coef, score, latent] = pca(rTrain);

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

kTr = knnclassify(rTrain,rTrain,emotTr,4);

kTest = knnclassify(rTest,rTrain,emotTr,4);

%calculate Training error
error = sum(kTr ~= emotTr);
trainErrorKnn = (error/length(emotTr))*100
%Train Error 0 percent

%calculate Training error
error = sum(kTest ~= emotTest);
trainErrorKnn = (error/length(emotTest))*100
%Train Error 0 percent



%%%%%%%%%%%%%%%%%%%%%%  REGRESSION  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%%Regression I don't think this is a good idea
%%%%%%%%%%%%%%%%%%%%%%%%%%%  TRAIN MODEL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

w = mldivide((rTrain'*rTrain),(rTrain'*vaTrain));


%predict

u = rTrain*w;












