/* BoschSensortec routines here: https://github.com/BoschSensortec/BME280_driver/tree/master
 * This version taken from NodeMCU project
 *	https://github.com/nodemcu/nodemcu-firmware/blob/dev/app/modules/bme280.c
*/

#include <math.h>

#include "udp.h"
#include "bme280.h"
#include "bme280-cal.h"

#define S32	int32_t
#define U32	uint32_t
#define S64	int64_t

static S32 bme280_t_fine;

int32_t bme280_compensate_T (struct bme280_data *d, int32_t adc_T)
{
	S32 var1, var2, T;

	var1  = ((((adc_T>>3) - ((S32)d->dig_T1<<1))) * ((S32)d->dig_T2)) >> 11;
	var2  = (((((adc_T>>4) - ((S32)d->dig_T1)) * ((adc_T>>4) - ((S32)d->dig_T1))) >> 12) * ((S32)d->dig_T3)) >> 14;
	bme280_t_fine = var1 + var2;
	T  = (bme280_t_fine * 5 + 128) >> 8;

	return T;
}

int32_t bme280_compensate_H(struct bme280_data *d, int32_t adc_H)
{
	S32 v_x1_u32r;

	v_x1_u32r = (bme280_t_fine - ((S32)76800));
	v_x1_u32r = (((((adc_H << 14) - (((S32)d->dig_H4) << 20) - (((S32)d->dig_H5) * v_x1_u32r)) +
		((S32)16384)) >> 15) * (((((((v_x1_u32r * ((S32)d->dig_H6)) >> 10) * (((v_x1_u32r *
		((S32)d->dig_H3)) >> 11) + ((S32)32768))) >> 10) + ((S32)2097152)) *
		((S32)d->dig_H2) + 8192) >> 14));
	v_x1_u32r = (v_x1_u32r - (((((v_x1_u32r >> 15) * (v_x1_u32r >> 15)) >> 7) * ((S32)d->dig_H1)) >> 4));
	v_x1_u32r = (v_x1_u32r < 0 ? 0 : v_x1_u32r);
	v_x1_u32r = (v_x1_u32r > 419430400 ? 419430400 : v_x1_u32r);
	v_x1_u32r = v_x1_u32r>>12;
	return (U32)((v_x1_u32r * 1000)>>10);
}

int32_t bme280_compensate_P(struct bme280_data *d, int32_t adc_P)
{
	S64 var1, var2, p;
	var1 = ((S64)bme280_t_fine) - 128000;
	var2 = var1 * var1 * (S64)d->dig_P6;
	var2 = var2 + ((var1*(S64)d->dig_P5)<<17);
	var2 = var2 + (((S64)d->dig_P4)<<35);
	var1 = ((var1 * var1 * (S64)d->dig_P3)>>8) + ((var1 * (S64)d->dig_P2)<<12);
	var1 = (((((S64)1)<<47)+var1))*((S64)d->dig_P1)>>33;
	if (var1 == 0) {
		return 0; // avoid exception caused by division by zero
	}
	p = 1048576-adc_P;
	p = (((p<<31)-var2)*3125)/var1;
	var1 = (((S64)d->dig_P9) * (p>>13) * (p>>13)) >> 25;
	var2 = (((S64)d->dig_P8) * p) >> 19;
	p = ((p + var1 + var2) >> 8) + (((S64)d->dig_P7)<<4);
	p = (p * 10) >> 8;
	return (U32)p;
}

int32_t bme280_qfe2qnh(struct bme280_data *d, int32_t qfe, int32_t h)
{
	static uint32_t bme280_h = 0;
	static double bme280_hc = 1.0;
	double hc;

	if (bme280_h == h) {
		hc = bme280_hc;
	} else {
		hc = pow((double)(1.0 - 2.25577e-5 * h), (double)(-5.25588));
		bme280_hc = hc; bme280_h = h;
	}
	double qnh = (double)qfe * hc;
	return qnh;
}

