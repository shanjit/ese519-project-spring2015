//ads1299.h

#ifndef _ADS1299_h
#define _ADS1299_h

#include <stdint.h>

int initLibrary();
uint8_t transferData(uint8_t);
void transferComplete();


void reset();
uint8_t getDeviceId();

// Implement later
// uint8_t transfernData(uint8_t);


#endif