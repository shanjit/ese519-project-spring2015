// main.c


// #ifndef ____ADS1299__
// #define ____ADS1299__


// Variable naming convention
// All functionss are camelCase
// All variables are first letter capital: InitLibrary

#include "ads1299.h"
#include <stdio.h>
#include <stdint.h>




int main(int argc, char **argv)
{

	// Initialize the library 
	// Pin Numbers 
	// MOSI - P19 on J8 on Pi B+ 
	// MISO - P21 on J8 on Pi B+
	// SS - P24 on J8 on Pi B+
	// SCLK - P23 on J8 on Pi B+
	// GND - P25 on J8 on Pi B+
	// Note : The CS is automatically managed by the library

	// SPI Mode configuration and set DRDY pin to be input
	int val = initLibrary();
	//printf("%d", val);
	if(val!=0)
	{
		printf("Initialization problem \n Exiting \n");
		return 23;
	}

		

	
	// reset ads1299
	reset(); 

	uint8_t DeviceId = getDeviceId();
	printf("Device Id is %02x \n", DeviceId);

	/*
	if (DeviceId==0xff)
	{
		printf("Incorrect configuration.\n");
	}

	else
	{
		printf("Correct configuration. \n");
	}
	*/
	


	transferComplete();

	return 0;
}


/*

	blinky code - use for debug later

    // Set the pin to be an output
    bcm2835_gpio_fsel(PIN_DRDY, BCM2835_GPIO_FSEL_OUTP);

	// Turn it on
    bcm2835_gpio_write(PIN, HIGH);
        
    // wait a bit
    bcm2835_delay(500);
        
    // turn it off
    bcm2835_gpio_write(PIN, LOW);
        
    // wait a bit
    bcm2835_delay(500);
	
*/
