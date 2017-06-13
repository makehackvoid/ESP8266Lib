#ifndef _ADC_H
#define _ADC_H

/* adc.c */
esp_err_t read_vdd (float *vdd);
esp_err_t read_bat (float *bat);

#endif // _ADC_H
