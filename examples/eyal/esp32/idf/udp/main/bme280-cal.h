#ifndef _BME280_CAL_H
#define _BME280_CAL_H

#define BME280_S32_t	int32_t
#define BME280_U32_t	uint32_t
#define BME280_S64_t	int64_t

struct bme280_data {
	uint16_t  dig_T1;
	int16_t   dig_T2;
	int16_t   dig_T3;
	uint16_t  dig_P1;
	int16_t   dig_P2;
	int16_t   dig_P3;
	int16_t   dig_P4;
	int16_t   dig_P5;
	int16_t   dig_P6;
	int16_t   dig_P7;
	int16_t   dig_P8;
	int16_t   dig_P9;
	uint8_t   dig_H1;
	int16_t   dig_H2;
	uint8_t   dig_H3;
	int16_t   dig_H4;
	int16_t   dig_H5;
	int8_t    dig_H6;
};

int32_t bme280_compensate_T (struct bme280_data *d, int32_t adc_T);
int32_t bme280_compensate_H(struct bme280_data *d, int32_t adc_H);
int32_t bme280_compensate_P(struct bme280_data *d, int32_t adc_P);
int32_t bme280_qfe2qnh(struct bme280_data *d, int32_t qfe, int32_t alt);

#endif  // _BME280_CAL_H
