# -*- coding: utf-8 -*-
"""
This is a file to test that the features extracted using this method in python
is identical to the values found in the MATLAB model
"""
import numpy as np
from pylab import *

############################################
# Define all constants here

alpha = array([10, 12]);
sAlpha = array([8, 10]);
beta = array([12, 27]);
gamma = array([27, 45]);
theta = array([3, 8]);
delta = array([0.2, 3]);

freqBands = array([alpha,
               sAlpha,
                 beta,
                    gamma,
                       theta,
                          delta]);  

winLen = 4;  #Seconds
winDisp = 1; #Seconds

ch = array([27, 3, 6, 2, 24, 7, 11, 20]); #channels of interest 4-Front 2-Temp 2-Occ
##########################################
# Functions

def NumWins(xLen,fs,winLen,winDisp): 
    return round((xLen-(winLen - winDisp)*fs)/(winDisp*fs));
    
def LLFn(x): 
    return sum(abs(np.diff(x)));
###########################################
#Get the data from somewhere

#csv
labels = np.loadtxt('C:\Users\Jared\Dropbox\DEAPdatasets\Preprocessed_csv\s01Labels.csv',delimiter=',')
data = np.loadtxt('C:\Users\Jared\Dropbox\DEAPdatasets\Preprocessed_csv\s01Datav2.csv',delimiter=',',usecols=range(1,8064),skiprows=0)


#Spectrogram dependent Information
NFFT = 512;       # the length of the windowing segments
Fs = 128;  # the sampling frequency
dt = 1/float(Fs);
t = arange(0.0, int(data.shape[1])/float(Fs), dt)

windows = NumWins(int(data.shape[1]), Fs, winLen, winDisp);
dispSamp = winDisp*Fs;  #Displacement in terms of samples

"""    
#################SPECTROGRAM EXAMPLE (PLOT INCLUDED)##########################
# Pxx is the segments x freqs array of instantaneous power, freqs is
# the frequency vector, bins are the centers of the time bins in which
# the power is computed, and im is the matplotlib.image.AxesImage
# instance
 
ax1 = subplot(211)
plot(t, data[1,:])
subplot(212, sharex=ax1)
Pxx, freqs, bins, im = specgram(data[1,:], NFFT=NFFT, Fs=Fs, noverlap=384,
                                cmap=cm.gist_heat)
show()
"""
#######################################################################
#Feature extraction starts here


for i in range(0,(ch.size)):

    Pxx, freqs, bins, im = specgram(data[ch[i],:], NFFT=NFFT, Fs=Fs,
                                    noverlap=(winLen-winDisp)*Fs, cmap=None);
            #below this line is matlab code
#########################################################
                                
   freqFeats = array([[],[]]);
   for j in range(0,windows):

       bandInds = np.logical_and(freqs >= freqBands[j,0] , freqs <= freqBands[j,1]);
       freqFeats[j,:] = np.mean(abs(Pxx[bandInds,:]),1);
        
   C = conv(x(i,:),ones(1,winLen*fs)/(winLen*fs),'valid');
   timeavg_bin = C(1:(winDisp)*fs:end)';

   LL = MovingWinFeats(x(i,:), fs, winLen, winDisp, LLFn);
    
   #F,T,O (Frontal, Temporal, and Occipital assymetry index)
   #kept addition row of zeros so could be formated into grid
   if i == 2  
       asymFeats(:,1:6) = (freqFeats' - F(:,end-6:end-1))./(freqFeats' + F(:,end-6:end-1));
   else if i == 6
       asymFeats(:,9:14) = (freqFeats' - F(:,end-6:end-1))./(freqFeats' + F(:,end-6:end-1));
   else if i == 8
        asymFeats(:,17:22) = (freqFeats' - F(:,end-6:end-1))./(freqFeats' + F(:,end-6:end-1));
        
    
    #make feature matrix
    F = [F freqFeats' timeavg_bin LL];

    fprintf('%d',i)   
    end
    
    F = [F asymFeats];
    



