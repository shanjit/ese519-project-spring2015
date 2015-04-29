# -*- coding: utf-8 -*-
"""
Created on Mon Apr 27 15:40:58 2015

@author: Jared
"""

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

import threading
import numpy as np
from pylab import *
from matplotlib import pyplot as plt
import scipy.io.wavfile as wav
from numpy.lib import stride_tricks
import struct
import pyqtgraph as pg

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
bufferSize = 30;  #number of windows to be added together
fTot = np.zeros([bufferSize,82])  #fTot size (num of windows x num of features)  
##########################################
# Set up spectral graph can comment out
plt = pg.plot()
curve = plt.plot()
plt.setRange(xRange=[0, 64], yRange=[0, 2000])
i = 0

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
	print win
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
#
# This is where the magic happens
#input val -  integer value of 24 bits rep
#input bits - number of bits in val 
#input Vref - This is the value that scales the ACD value

def adc2float(val, bits,Vref):
	"""compute the 2's compliment of int value val"""
	if (val & (1 << (bits - 1))) != 0: # if sign bit is set e.g., 8bit: 128-255
		val = val - (1 << bits)        # compute negative value
	
	#Scale val by Vref
	val = float(val)
	val = Vref * (val/(2**(bits-1) + 1))
	
	return val 
###################################################################################################
#THIS IS WHERE THE MAGIC HAPPENS


def getFeats():
	#GET DATA FROM BIN FILE
	f = open('input_eeg.txt','rb') 
	#tmp = f.read();      

	global data, curve, line, i, fTot
	windows = 1;
	n = 512  # update 10 samples per iteration
			#read from the binary file
	
	data = np.zeros([8, n]);    
##############################################################################
###########   THIS IS WHAT I WILL NEED TO CHANGE IN ORDER TO GET THE DATA FROM
###########   THE DATA FILE BEING STREAMED FROM THE rPi.
	tmp = [];
	j = 0;
	lines = f.readlines();

	#for line in f:
	for l in range(0,4):
		print l;
		line = lines[l];
		#if j==4:
		#break;
		Vref = 4.5;   #This value needs to be determined 5V right now. 
		tmp[:] = line[1:len(line)-1].split(':');
		tmp[:] = tmp[0:len(tmp)-1];
		#print tmp
		tmpInt = array([np.uint32(e) for e in tmp]);
		#print tmpInt.shape
		
		for foo in range(0,tmpInt.size):
			tmpInt[foo] = adc2float(tmpInt[foo], 24, Vref)*10**3
		
		size(tmp); 
		tmpInt2 =  np.transpose(np.reshape(tmpInt, (128,8)));        
		data[:,(j*128):(j*128)+128] = tmpInt2;
		j = j+1

		
	
	##########################################################################
	#COMPUTE FEATURES FOR THE DATA
	##########################################################################
	
	#Spectrogram dependent Information
	NFFT = 512;       # the length of the windowing segments
	Fs = 128;  # the sampling frequency
	dt = 1/float(Fs);
	t = arange(0.0, int(data.shape[1])/float(Fs), dt)
		
	totFeats = 82; #total number of features to be used
	
	#initialize arrays for faster computing
	asymFeats = np.empty([windows, (int(freqBands.shape[0])*3)],dtype = float)
	F  = np.empty([windows, totFeats],dtype = float);
	
	for ch in range(0,7):
			 
		freqs = np.zeros([257,1])     
		freqs[:,0] = array(range(0,64*4+1))/float(4)
				
		Pxx = stft(data[ch,:], winLen*Fs, overlapFac = 0.75, window = np.hanning)
		Pxx = np.transpose(Pxx)
		# print Pxx;	
		plot = np.append(freqs,abs(Pxx),axis = 1)
		curve.setData(plot)
		
		
		freqs = array(range(0,64*4+1))/float(4)     
		#init freq features vector to be size of ch x number of windows   
		freqFeats = np.empty([int(freqBands.shape[0]), windows],dtype = float)
		#freqFeats2 = np.empty([int(freqBands.shape[0]), windows],dtype = float)
		
			
		for j in range(0,int(freqBands.shape[0])):
			bandInds = np.logical_and(freqs >= freqBands[j,0] , freqs <= freqBands[j,1]);
			#freqFeats[j,:] = np.mean(np.abs(Pxx[bandInds,:]),0);
			freqFeats[j,:] = np.mean(np.abs(Pxx[bandInds,:]),0);
			#end loop
			
		timeavg_bin = np.empty([windows,1]);    
		timeavg_bin[0,0] = np.mean(data[ch,:])
		#timeavg_bin = np.empty([windows,1]);    
		#C = np.convolve(data[ch,:],np.ones(winLen*Fs)/(winLen*Fs),'valid');
		#timeavg_bin[:,0] = C[0:C.size:(winDisp)*Fs];
	   
	   
		#Time Windowed Features
		LL = np.empty([windows,1]);
		LL[0,0] = LLFn(data[ch,:]);
		
	
				#below this line is matlab code
	#########################################################
	   #F,T,O (Frontal, Temporal, and Occipital assymetry index)
	   #kept addition row of zeros so could be formated into grid
		if ch == 1:  
			asymFeats[:,0:6] = (np.transpose(freqFeats) - F[:,0:6])/(np.transpose(freqFeats) + F[:,0:6]);
		elif ch == 5:
			asymFeats[:,6:12] =  (np.transpose(freqFeats) - F[:,32:38])/(np.transpose(freqFeats) + F[:,32:38]);
		elif ch == 7:
			asymFeats[:,12:18] =  (np.transpose(freqFeats) - F[:,48:54])/(np.transpose(freqFeats) + F[:,48:54]);
		
		#make feature matrix
		tmp = np.append(np.transpose(freqFeats), (timeavg_bin),axis = 1)
		F[:,(ch*7):(ch*7)+8] = np.append(tmp, LL,axis = 1)
		#end loop

		
	F[:,-18:] = asymFeats;
	print F;
	#add current F to circular F buffer to be averaged
	fTot[i,:] = F;
	i = (i+1) % bufferSize;
	#print(i)   
	threading.Timer(2, getFeats).start()

	
"""   
Load baseline featavg and featstd for normalization 
HOW????
	for i in range(0,totFeats):
		F[:,i] = (F[:,i] - featAv[i])/featStd[i]
   """     
i = 0;
getFeats();
