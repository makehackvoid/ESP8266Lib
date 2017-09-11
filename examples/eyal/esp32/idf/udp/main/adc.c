/* ADC reading Example

   This example code is in the Public Domain (or CC0 licensed, at your option.)

   Unless required by applicable law or agreed to in writing, this
   software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
   CONDITIONS OF ANY KIND, either express or implied.
*/

#include "udp.h"
#include "adc.h"
#include "esp_adc_cal.h"

#include <driver/adc.h>

#define ADC_ATTEN	ADC_ATTEN_6db
#define ADC_ATTEN_RATIO	(4095. / 2)

static adc_atten_t adc_width = ADC_WIDTH_12Bit;
static int adc_vref = 1199;

esp_err_t adc_init (int width, int vref)
{
	switch (width) {
	case  9:
		adc_width = ADC_WIDTH_9Bit;
		break;
	case 10:
		adc_width = ADC_WIDTH_10Bit;
		break;
	case 11:
		adc_width = ADC_WIDTH_11Bit;
		break;
	case 12:
		adc_width = ADC_WIDTH_12Bit;
		break;
	default:
		LogR (ESP_FAIL, "bad ADC width %d", width);
		break;
	}

	DbgR (adc1_config_width(adc_width));

	adc_vref = vref;

	return ESP_OK;
}

esp_err_t adc_read (float *adc, uint8_t pin, int atten, float divider)
{
	adc1_channel_t channel;
	adc_atten_t adc_atten;

	*adc = 0.0;

	switch (pin) {
	case  36:
		channel = ADC1_CHANNEL_0;
		break;
	case  37:
		channel = ADC1_CHANNEL_1;
		break;
	case  38:
		channel = ADC1_CHANNEL_2;
		break;
	case  39:
		channel = ADC1_CHANNEL_3;
		break;
	case  32:
		channel = ADC1_CHANNEL_4;
		break;
	case  33:
		channel = ADC1_CHANNEL_5;
		break;
	case  34:
		channel = ADC1_CHANNEL_6;
		break;
	case  35:
		channel = ADC1_CHANNEL_7;
		break;
	default:
		LogR (ESP_FAIL, "bad ADC pin %d", pin);
		break;
	}

	switch (atten) {
	case 0:
		adc_atten = ADC_ATTEN_0db;
		break;
	case 2:
		adc_atten = ADC_ATTEN_2_5db;
		break;
	case 6:
		adc_atten = ADC_ATTEN_6db;
		break;
	case 11:
		adc_atten = ADC_ATTEN_11db;
		break;
	default:
		LogR (ESP_FAIL, "bad ADC atten %d", atten);
		break;
	}

	DbgR (adc1_config_channel_atten(channel, adc_atten));
	esp_adc_cal_characteristics_t cal;
	esp_adc_cal_get_characteristics(adc_vref, adc_atten, adc_width, &cal);
	*adc = adc1_to_voltage(channel, &cal) / 1000. * divider;

	return ESP_OK;
}

