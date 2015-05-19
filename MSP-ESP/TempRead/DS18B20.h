#ifndef TEMPSENSOR_DS18B20_H_
#define TEMPSENSOR_DS18B20_H_

// Public function prototypes
unsigned char DS18B20_init();
void DS18B20_initiateConversion();
short DS18B20_GetCurrentTempX100();

short DS18B20_GetCurrentTempQ8_7();

#endif /* TEMPSENSOR_DS18B20_H_ */
