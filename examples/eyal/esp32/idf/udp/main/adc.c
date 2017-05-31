/* ADC reading Example

   This example code is in the Public Domain (or CC0 licensed, at your option.)

   Unless required by applicable law or agreed to in writing, this
   software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
   CONDITIONS OF ANY KIND, either express or implied.
*/

#include "udp.h"
#include "adc.h"

#include <driver/adc.h>

#define ADC_WIDTH       ADC_WIDTH_12Bit

//#define ADC_ATTEN	ADC_ATTEN_0db
//#define ADC_ATTEN_RATIO	(4095.)

#define ADC_ATTEN	ADC_ATTEN_6db
#define ADC_ATTEN_RATIO	(4095. / 2)

//#define ADC_ATTEN	ADC_ATTEN_11db
//#define ADC_ATTEN_RATIO	(4095. / 3.548134)

#define VDD_CHANNEL	ADC1_CHANNEL_4
#define VDD_DIVIDER	3.59	// measured

#define BAT_CHANNEL	ADC1_CHANNEL_5
#define BAT_DIVIDER	2.98	// measured

esp_err_t read_adc (float *bat, float *vdd)
{
	*bat = 0.0;
	*vdd = 0.0;

	DbgR (adc1_config_width(ADC_WIDTH));

	DbgR (adc1_config_channel_atten(VDD_CHANNEL, ADC_ATTEN));
	*vdd = adc1_get_voltage(VDD_CHANNEL) / (ADC_ATTEN_RATIO / VDD_DIVIDER);

	DbgR (adc1_config_channel_atten(BAT_CHANNEL, ADC_ATTEN));
	*bat = adc1_get_voltage(BAT_CHANNEL) / (ADC_ATTEN_RATIO / BAT_DIVIDER);

	return ESP_OK;
}
