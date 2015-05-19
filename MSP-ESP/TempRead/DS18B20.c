/*
* This library is an interpretation of code from several libraries including the Dallas Semi app note and Arduino OneWire library.
 * There has been enough contributors that have come and gone to those libraries to make the licencing a complete mess.
 * For my adaptations, it's public domain.
 */

#include <msp430.h>
#include "DS18B20.h"

// Pin Definitions
#define DirectionPort 	P1DIR
#define InputPort	  	P1IN
#define OutputPort		P1OUT
#define DS18B20_Pin		BIT7

#define CPU_MHz	8

// Private function prototypes
void DS18B20_Data_Write(unsigned char pinState);
unsigned char DS18B20_Data_Read();

unsigned char OneWireInByte();
void OneWireOutByte(unsigned char data);
unsigned char OneWireReset();

unsigned char DS18B20_init()
{
	DirectionPort &= ~DS18B20_Pin;  // Clear the direction pin
	OutputPort &= ~DS18B20_Pin;

    // Give time for the power to the peripheral to stabalise
    __delay_cycles(1000 * CPU_MHz);
    return OneWireReset();
    // Note: not setting the config register,
    // therefore the default startup of 12bit resolution is used.
}

void DS18B20_initiateConversion()
{
    OneWireReset();
    OneWireOutByte(0xcc); // Skip ROM command (address all devices on the bus)
    OneWireOutByte(0x44); // perform temperature conversion
}

short DS18B20_GetCurrentTempX100()
{
    unsigned char HighByte, LowByte;
    short TReading;

    OneWireReset();
    OneWireOutByte(0xcc);  // Skip ROM command (address all devices on the bus)
    OneWireOutByte(0xbe);  // Read Scratchpad command

    __delay_cycles(100);

    LowByte = OneWireInByte();
    HighByte = OneWireInByte();
    TReading = (HighByte << 8) + LowByte;

    if (TReading & 0x8000) // negative
    {
        TReading = (TReading ^ 0xffff) + 1;   // 2's comp
    }

    return (6 * TReading) + (TReading >> 2);    // multiply by (100 * 0.0625) or 6.25
}

unsigned char OneWireReset()
{
    short i;
    unsigned char response = 1;

    __disable_interrupt();

    DS18B20_Data_Write(0);
    __delay_cycles(500 * CPU_MHz);
    DS18B20_Data_Write(1);
    __delay_cycles(15 * CPU_MHz);
    // The DS18B20 now must respond by pulling the bus low at some point in the next 240us
    for(i=60; i>0; i--)
    {
        __delay_cycles(1 * CPU_MHz);
        if(DS18B20_Data_Read() == 0)
        {
            response = 0;
        }
    }

    __enable_interrupt();
    return response;
}

void OneWireOutByte(unsigned char data)
{
    int i;
    __disable_interrupt();

    for(i=0; i<8; i++)
    {
        if(data & 0x01)
        {
            // High bit
            DS18B20_Data_Write(0);
            __delay_cycles(5 * CPU_MHz);
            DS18B20_Data_Write(1);
            __delay_cycles(60 * CPU_MHz);
        }
        else
        {
            //Low Bit
            DS18B20_Data_Write(0);
            __delay_cycles(65 * CPU_MHz);
            DS18B20_Data_Write(1);
            __delay_cycles(5 * CPU_MHz);
        }
        data = data >> 1;
    }
    __enable_interrupt();
}

unsigned char OneWireInByte()
{
    int i;
    unsigned char temp, data;

    __disable_interrupt();

    for (i=0; i<8; i++)
    {
        DS18B20_Data_Write(0);
        __delay_cycles(5 * CPU_MHz);
        DS18B20_Data_Write(1);
        __delay_cycles(5 * CPU_MHz);
        temp = DS18B20_Data_Read();
        __delay_cycles(50 * CPU_MHz);
        data = (data >> 1) | (temp << 7);
    }
    __enable_interrupt();
    return(data);
}

void DS18B20_Data_Write(unsigned char pinState)
{
	// A logical high will open the pin, as in the pull up state
	if(pinState)
	{
		DirectionPort &= ~DS18B20_Pin;
	} else {
		DirectionPort |= DS18B20_Pin;
	}
}

unsigned char DS18B20_Data_Read()
{
	if(InputPort & DS18B20_Pin)
		return 1;
	else
		return 0;
}

