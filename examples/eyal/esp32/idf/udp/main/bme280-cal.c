/* BoschSensortec routines here: https://github.com/BoschSensortec/BME280_driver/tree/master
*/

#include "udp.h"
#include "bme280.h"
#include "bme280-cal.h"

#define BME280_S32_t	int32_t
#define BME280_U32_t	uint32_t
#define BME280_S64_t	int64_t

static BME280_S32_t bme280_t_fine;	// not yet used

int32_t bme280_compensate_T (struct bme280_data *d, int32_t adc_T)
{
	BME280_S32_t var1, var2, T;

	var1  = ((((adc_T>>3) - ((BME280_S32_t)d->dig_T1<<1))) * ((BME280_S32_t)d->dig_T2)) >> 11;
	var2  = (((((adc_T>>4) - ((BME280_S32_t)d->dig_T1)) * ((adc_T>>4) - ((BME280_S32_t)d->dig_T1))) >> 12) * ((BME280_S32_t)d->dig_T3)) >> 14;
	bme280_t_fine = var1 + var2;
	T  = (bme280_t_fine * 5 + 128) >> 8;

	return T;
}

int32_t bme280_compensate_H(struct bme280_data *d, int32_t adc_H)
{
	return adc_H;	// dummy
}

int32_t bme280_compensate_P(struct bme280_data *d, int32_t adc_P)
{
	return adc_P;	// dummy
}

int32_t bme280_qfe2qnh(struct bme280_data *d, int32_t qfe, int32_t alt)
{
	return qfe;	// dummy
}

