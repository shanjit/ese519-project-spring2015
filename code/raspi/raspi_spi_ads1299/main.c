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

	int val = initLibrary();
	
	printf("%d", val);

	if(val!=0)
	return 23;

	while(1)
	{
	uint8_t send_data = 0xaa;
    uint8_t read_data = transferData(send_data);

    printf("%02x\n", read_data);

	}

	transferComplete();



	return 0;
}
