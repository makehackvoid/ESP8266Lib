#ifndef _ADC_H
#define _ADC_H

/* adc.c */
esp_err_t adc_init (int width, int vref);
esp_err_t adc_read (float *adc, uint8_t pin, int atten, float divider);

#endif // _ADC_H
