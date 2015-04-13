// main.c
// This code is used to hack the ADS1299 development kit (http://www.ti.com/tool/ads1299eegfe-pdk) using a raspberry pi plus board.
// Written by Shanjit Singh Jajmann
// Other resources used - bcm2835 library used for Raspi BPlus pin access
// ESE 519 Project at the University of Pennsylvania

// Variable naming convention
// All functions are camelCase
// All variables are small case
// All macros are CAPS

// Pin Connections on hardware 
// MOSI - P19 on J8 on Pi B+ 
// MISO - P21 on J8 on Pi B+
// SS - P18 on J8 on Pi B+
// SCLK - P23 on J8 on Pi B+
// GND - P25 on J8 on Pi B+
// DRDY - Pin 22 on J8 on Pi B+
// clk config on the board on startup

#define RREG_READ 1
#define RREG_WRITE 0

#include <stdio.h>
// for printf

#include <stdint.h>
// for uint8_t datatypes

#include "definitions.h"
// for all pin definitions and constants

#include "ads1299.h"
// for the custom ads1299 library

// debugging code
#define DEBUG 1

// return codes - echo $?
// -1: library initialization failed
// -2: incorrect device id, check SPI
// 

int main(int argc, char **argv)
{
	// initialize library
	if(!initLibrary())
		return -1;

	// variable to get/put spi data throughout this file
	uint8_t data;

	data = getDeviceId();

	// print device id
	printf("Device ID %02x\n", data);
	
	// exit if incorrect device id
	if (data!=0x3e)
	{
		printf("Incorrect Device ID detected, Exiting\n");
		return -2;
	}

	// print all configuration registers
/*	rregTransferData(RREG_READ, uint8_t , uint8_t)

	transferData(0x21);
	transferData(0x00);
	readData = transferData(0x00);
	printf("config register is %02x \n", readData);

	bcm2835_delayMicroseconds(1000);
*/
    


	transferComplete();
	
	return 0;
}



