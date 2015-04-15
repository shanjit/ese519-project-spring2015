#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <sys/ioctl.h>
#include <linux/spi/spidev.h>

#include <wiringPi.h>


#define	PIN_CS	 2 // Physical Pin 13 on the raspi bplus 
#define PIN_DRDY 3 // Physical Pin 15 on the raspi bplus

//SPI Command Definition Byte Assignments (Datasheet, pg. 35)
#define _WAKEUP 0x02 // Wake-up from standby mode
#define _STANDBY 0x04 // Enter Standby mode
#define _RESET 0x06 // Reset the device
#define _START 0x08 // Start and restart (synchronize) conversions
#define _STOP 0x0A // Stop conversion
#define _RDATAC 0x10 // Enable Read Data Continuous mode (default mode at power-up)
#define _SDATAC 0x11 // Stop Read Data Continuous mode
#define _RDATA 0x12 // Read data by command; supports multiple read back

#define _RREG 0x20 // (also = 00100000) is the first opcode that the address must be added to for RREG communication
#define _WREG 0x40 // 01000000 in binary (Datasheet, pg. 35)



#define TCLK 0.4882815 // microseconds
#define FCLK 2.048
#define DEBUG 1 



// The SPI bus parameters
//	Variables as they need to be passed as pointers later on

const static char       *spiDev0  = "/dev/spidev0.0" ;
const static char       *spiDev1  = "/dev/spidev0.1" ;
const static uint8_t     spiBPW   = 8 ; // Bytes per word
const static uint16_t    spiDelay = 0 ;
static uint8_t	 mode = 1;


static uint32_t    spiSpeeds [2] ;
static int         spiFds [2] ;

unsigned char dataTransfer (unsigned char *data, int len)
{
  struct spi_ioc_transfer spi ;

  int channel = 0 ;

  memset (&spi, 0, sizeof (spi)) ;

  spi.tx_buf        = (unsigned long)data ;
  spi.rx_buf        = (unsigned long)data ;
  spi.len           = len ;
  spi.delay_usecs   = spiDelay ;
  spi.speed_hz      = spiSpeeds [channel] ;
  spi.bits_per_word = spiBPW ;

  return ioctl (spiFds [channel], SPI_IOC_MESSAGE(1), &spi) ;
}


int spiSetup ()
{
  int fd ;

  int mode    = 1 ;	// Mode is 0, 1, 2 or 3
  int channel = 0 ;	// Channel is 0 or 1
  int speed = 1000000;
  if ((fd = open (channel == 0 ? spiDev0 : spiDev1, O_RDWR)) < 0)
	return -1;
  spiSpeeds [channel] = speed ;
  spiFds    [channel] = fd ;

// Set SPI parameters.

  if (ioctl (fd, SPI_IOC_WR_MODE, &mode)            < 0)
	return -1;  
  if (ioctl (fd, SPI_IOC_WR_BITS_PER_WORD, &spiBPW) < 0)
	return -1;
  if (ioctl (fd, SPI_IOC_WR_MAX_SPEED_HZ, &speed)   < 0)
	return -1;
  return fd ;
}


int main()
{	
	int fd = spiSetup();
	
	if(fd < -1)
	{
		printf("bad file descriptor");
		
	}
	
	
	// Setup wiringPi
	wiringPiSetup ();
	
	pinMode(PIN_CS, OUTPUT);
	pinMode(PIN_DRDY, INPUT);
	
	digitalWrite(PIN_CS, LOW);
	// 1000 milliseconds delay to make sure the chip select is all set
	delay(1000);

	unsigned char data;
	data = 0x60;
	dataTransfer(&data,sizeof(data));
	
	delayMicroseconds(20*TCLK);
	
	data = 0x11;
	dataTransfer(&data,sizeof(data));

	delayMicroseconds(4*TCLK);	
	

	data = 0x20;
	dataTransfer(&data,sizeof(data));
		
	data = 0x00;
	dataTransfer(&data,sizeof(data));
	
	data = 0x00;
	dataTransfer(&data,sizeof(data));

	printf("Device ID is %02x \n", data);
	
	// restart the _RDATAC mode
	// dataTransfer(0x10);
	
	
	return 0;
	
	
}



