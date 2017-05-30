#ifndef _BME280_H
#define _BME280_H

/* bme280.c */
esp_err_t bme280_init (uint8_t sda, uint8_t scl, int full);
esp_err_t bme280_temp (float *temp);

#endif	// _BME280_H
