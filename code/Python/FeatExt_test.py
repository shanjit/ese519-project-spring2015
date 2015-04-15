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
#used to comput the num of windows
def NumWins(xLen,fs,winLen,winDisp): 
    return round((xLen-(winLen - winDisp)*fs)/(winDisp*fs));

#used to compute line Length    
def LLFn(x): 
    return sum(abs(np.diff(x)));
###########################################
#Get the data from somewhere

#csv
labels = np.loadtxt('C:\Users\Jared\Dropbox\DEAPdatasets\Preprocessed_csv\s01Labels.csv',delimiter=',')
data = np.loadtxt('C:\Users\Jared\Dropbox\DEAPdatasets\Preprocessed_csv\s01Datav2.csv',delimiter=',',usecols=range(1,8064*20),skiprows=0)


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
totFeats = 82; #total number of features to be used

#initialize arrays for faster computing
asymFeats = np.empty([windows, (int(freqBands.shape[0])*3)],dtype = float)
F  = np.empty([windows, totFeats],dtype = float);

for i in range(0,(ch.size)):
    
    Pxx, freqs, bins = specgram(data[ch[i],:], NFFT=NFFT, Fs=Fs, window=mlab.window_hanning, noverlap=(winLen-winDisp)*Fs, cmap=None);



    #init freq features vector to be size of ch x number of windows   
    freqFeats = np.empty([int(freqBands.shape[0]), int(Pxx.shape[1])],dtype = float)
        
    for j in range(0,int(freqBands.shape[0])):
        bandInds = np.logical_and(freqs >= freqBands[j,0] , freqs <= freqBands[j,1]);
        freqFeats[j,:] = np.mean(np.abs(Pxx[bandInds,:]),0);
        #end loop
       
    timeavg_bin = np.empty([windows,1]);    
    C = np.convolve(data[ch[i],:],np.ones(winLen*Fs)/(winLen*Fs),'valid');
    timeavg_bin[:,0] = C[1:C.size:(winDisp)*Fs];
   
   
    #Time Windowed Features
    xWin = np.empty([windows,winLen*Fs],dtype = float);
    LL = np.empty([windows,1]);
    for w in range(0,int(windows)):
        xWin[w,:] = data[ch[i],(w)*dispSamp:(w)*dispSamp + winLen*Fs];    
        LL[w] = LLFn(xWin[w,:]);
    

            #below this line is matlab code
#########################################################
   #F,T,O (Frontal, Temporal, and Occipital assymetry index)
   #kept addition row of zeros so could be formated into grid
    if i == 1:  
        asymFeats[:,0:6] = (np.transpose(freqFeats) - F[:,0:6])/(np.transpose(freqFeats) + F[:,0:6]);
    elif i == 5:
        asymFeats[:,6:12] =  (np.transpose(freqFeats) - F[:,32:38])/(np.transpose(freqFeats) + F[:,32:38]);
    elif i == 7:
        asymFeats[:,12:18] =  (np.transpose(freqFeats) - F[:,48:54])/(np.transpose(freqFeats) + F[:,48:54]);
    
    #make feature matrix
    tmp = np.append(np.transpose(freqFeats), (timeavg_bin),axis = 1)
    F[:,(i*ch.size):(i*ch.size)+8] = np.append(tmp, LL,axis = 1)

    print(i)   
    #end loop
    
F[:,-18:] = asymFeats;

featAv = np.mean(F,0);
featStd = np.std(F,0); 
    
for i in range(0,totFeats):
    F[:,i] = (F[:,i] - featAv[i])/featStd[i]


