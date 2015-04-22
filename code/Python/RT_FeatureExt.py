# -*- coding: utf-8 -*-
"""
Created on Tue Apr 21 21:41:58 2015

This code will be used to continually monitor data and extract features from 
four (4) second windows. 

The data is retrieved from a .dat file that is updated by the Rpi every 
one (1) second with the latest 4 second window.
^This allows for 4 second window with 3 second overlap between windows as in 
the training model

@author: Jared
"""


import numpy as np
from pylab import *
from matplotlib import pyplot as plt
import scipy.io.wavfile as wav
from numpy.lib import stride_tricks

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
ch = ch - 1;
##########################################
# Functions
#used to comput the num of windows
def NumWins(xLen,fs,winLen,winDisp): 
    return round((xLen-(winLen - winDisp)*fs)/(winDisp*fs));

#used to compute line Length    
def LLFn(x): 
    return sum(abs(np.diff(x)));
    
    
#Try this for stft instead of spectrogram
""" short time fourier transform of audio signal """
def stft(sig, frameSize, overlapFac=0.75, window=np.hanning):
    win = window(frameSize)
    hopSize = int(frameSize - np.floor(overlapFac * frameSize))
    
    # zeros at beginning (thus center of 1st window should be for sample nr. 0)
    #samples = np.append(np.zeros(np.floor(frameSize/2.0)), sig)  changed
    samples = sig;
    # cols for windowing
    cols = np.ceil( (len(samples) - frameSize) / float(hopSize)) + 1
    # zeros at end (thus samples can be fully covered by frames)
    samples = np.append(samples, np.zeros(frameSize))
    
    frames = stride_tricks.as_strided(samples, shape=(cols, frameSize), strides=(samples.strides[0]*hopSize, samples.strides[0])).copy()
    frames *= win
    
    return np.fft.rfft(frames)  
###################################################################################################
#THIS IS WHERE THE MAGIC HAPPENS


def update():
    #GET DATA FROM BIN FILE



    #COMPUTE FEATURES FOR THE DATA


    #Spectrogram dependent Information
    NFFT = 512;       # the length of the windowing segments
    Fs = 128;  # the sampling frequency
    dt = 1/float(Fs);
    t = arange(0.0, int(data.shape[1])/float(Fs), dt)
        
    totFeats = 82; #total number of features to be used
    
    #initialize arrays for faster computing
    asymFeats = np.empty([windows, (int(freqBands.shape[0])*3)],dtype = float)
    F  = np.empty([windows, totFeats],dtype = float);
    
    for i in range(0,(ch.size)):
        
        Pxx, freqs, bins, im = specgram(data[ch[i],:], NFFT=NFFT, Fs=Fs, window=mlab.window_hanning, noverlap=(winLen-winDisp)*Fs, cmap=None);
       
        test = stft(data[ch[i],:], winLen*Fs, overlapFac = 0.75, window = np.hanning)
        test = np.transpose(test)
    
        #init freq features vector to be size of ch x number of windows   
        freqFeats = np.empty([int(freqBands.shape[0]), windows],dtype = float)
        #freqFeats2 = np.empty([int(freqBands.shape[0]), windows],dtype = float)
    
            
        for j in range(0,int(freqBands.shape[0])):
            bandInds = np.logical_and(freqs >= freqBands[j,0] , freqs <= freqBands[j,1]);
            #freqFeats[j,:] = np.mean(np.abs(Pxx[bandInds,:]),0);
            freqFeats[j,:] = np.mean(np.abs(test[bandInds,:]),0);
            #end loop
           
        timeavg_bin = np.empty([windows,1]);    
        C = np.convolve(data[ch[i],:],np.ones(winLen*Fs)/(winLen*Fs),'valid');
        timeavg_bin[:,0] = C[0:C.size:(winDisp)*Fs];
       
       
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
        
    

