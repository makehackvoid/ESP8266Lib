/* ADC reading Example

   This example code is in the Public Domain (or CC0 licensed, at your option.)

   Unless required by applicable law or agreed to in writing, this
   software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
   CONDITIONS OF ANY KIND, either express or implied.
*/

#include "udp.h"
#include "adc.h"

#include <driver/adc.h>

#define ADC_ATTEN	ADC_ATTEN_6db
#define ADC_ATTEN_RATIO	(4095. / 2)

static int adc_range = 4096-1;

esp_err_t adc_init (int width)
{
	adc_atten_t adc_width;

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
		return ESP_FAIL;
	}

	DbgR (adc1_config_width(adc_width));
	adc_range = (1<<width) - 1;

	return ESP_OK;
}

esp_err_t adc_read (float *adc, uint8_t pin, int atten, float divider)
{
	adc1_channel_t channel;
	adc_atten_t adc_atten;
	float ratio;

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
		return ESP_FAIL;
	}

	switch (atten) {
	case 0:
		adc_atten = ADC_ATTEN_0db;
		ratio = adc_range / 1. / divider;
		break;
	case 2:
		adc_atten = ADC_ATTEN_2_5db;
		ratio = adc_range / 1.34 / divider;
		break;
	case 6:
		adc_atten = ADC_ATTEN_6db;
		ratio = adc_range / 2. / divider;
		break;
	case 11:
		adc_atten = ADC_ATTEN_11db;
		ratio = adc_range / 3.6 / divider;
		break;
	default:
		return ESP_FAIL;
	}

	DbgR (adc1_config_channel_atten(channel, adc_atten));
	*adc = adc1_get_voltage(channel) / ratio;

	return ESP_OK;
}

