# -*- coding: utf-8 -*-
"""
Created on Thu Apr 16 23:38:09 2015

@author: Jared
"""


import numpy as np
import pyqtgraph as pg
from pylab import *
import time

################################MOCK REAL TIME DATA###########################

#init the txt for data in
filename = "data.txt";
target = open(filename,'r')


for i in range(1000): 
    target.write(str(data[1,i]))
    target.write("\n")
    time.sleep(0.01)
    print(i);
    
print "Fin"
target.close();