/*
 * Licencing: Public Domain.
 *
 */

#include <msp430.h>				
#include "DS18B20.h"

volatile short temp;

int main(void) {
	WDTCTL = WDTPW | WDTHOLD;		// Stop watchdog timer

	// Set the clock to 8MHz
	BCSCTL1 = CALBC1_8MHZ;
	DCOCTL = CALDCO_8MHZ;

	if(DS18B20_init())
	{
		while(1);
	}

	for(;;)
	{
		DS18B20_initiateConversion();

		__delay_cycles(750000*8);

		temp = DS18B20_GetCurrentTempX100();

		__delay_cycles(100000*8);

	}
}
