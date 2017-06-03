#ifndef _DS18B20_H
#define _DS18B20_H

/* ds18b20.c */
esp_err_t ds18b20_get_temp(float *temp);
esp_err_t ds18b20_convert (int wait);
esp_err_t ds18b20_depower (void);
esp_err_t ds18b20_read_id (uint8_t *id);
esp_err_t ds18b20_init(uint8_t pin, uint8_t *id);

#endif	// _DS18B20_H
