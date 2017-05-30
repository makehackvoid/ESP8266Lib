#ifndef _DS18B20_H
#define _DS18B20_H

/* ds18b20.c */
esp_err_t ds18b20_init(uint8_t pin, uint8_t *id, int first);
esp_err_t ds18b20_get_temp(float *temp);
esp_err_t ds18b20_convert (void);
esp_err_t ds18b20_depower (void);

#endif	// _DS18B20_H
