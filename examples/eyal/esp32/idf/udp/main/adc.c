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

static adc_bits_width_t adc_width = ADC_WIDTH_12Bit;
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

#if 000
// see  components/driver/include/driver/adc.h
// and components/soc/esp32/include/soc/adc_channel.h
typedef enum {
    ADC1_CHANNEL_0 = 0, /*!< ADC1 channel 0 is GPIO36 */
    ADC1_CHANNEL_1,     /*!< ADC1 channel 1 is GPIO37 */
    ADC1_CHANNEL_2,     /*!< ADC1 channel 2 is GPIO38 */
    ADC1_CHANNEL_3,     /*!< ADC1 channel 3 is GPIO39 */
    ADC1_CHANNEL_4,     /*!< ADC1 channel 4 is GPIO32 */
    ADC1_CHANNEL_5,     /*!< ADC1 channel 5 is GPIO33 */
    ADC1_CHANNEL_6,     /*!< ADC1 channel 6 is GPIO34 */
    ADC1_CHANNEL_7,     /*!< ADC1 channel 7 is GPIO35 */
    ADC1_CHANNEL_MAX,
} adc1_channel_t;
typedef enum {
    ADC2_CHANNEL_0 = 0, /*!< ADC2 channel 0 is GPIO4 */
    ADC2_CHANNEL_1,     /*!< ADC2 channel 1 is GPIO0 */
    ADC2_CHANNEL_2,     /*!< ADC2 channel 2 is GPIO2 */
    ADC2_CHANNEL_3,     /*!< ADC2 channel 3 is GPIO15 */
    ADC2_CHANNEL_4,     /*!< ADC2 channel 4 is GPIO13 */
    ADC2_CHANNEL_5,     /*!< ADC2 channel 5 is GPIO12 */
    ADC2_CHANNEL_6,     /*!< ADC2 channel 6 is GPIO14 */
    ADC2_CHANNEL_7,     /*!< ADC2 channel 7 is GPIO27 */
    ADC2_CHANNEL_8,     /*!< ADC2 channel 8 is GPIO25 */
    ADC2_CHANNEL_9,     /*!< ADC2 channel 9 is GPIO26 */
    ADC2_CHANNEL_MAX,
} adc2_channel_t;
#endif

esp_err_t adc_read (float *adc, uint8_t pin, int atten, float divider)
{
	adc1_channel_t channel;
	adc_unit_t adc_unit;
	adc_atten_t adc_atten;

	*adc = 0.0;

	switch (pin) {
	case  0:
		channel = ADC2_GPIO0_CHANNEL;
		adc_unit = ADC_UNIT_2;
		break;
	case  2:
		channel = ADC2_GPIO2_CHANNEL;
		adc_unit = ADC_UNIT_2;
		break;
	case  4:
		channel = ADC2_GPIO4_CHANNEL;
		adc_unit = ADC_UNIT_2;
		break;
	case  12:
		channel = ADC2_GPIO12_CHANNEL;
		adc_unit = ADC_UNIT_2;
		break;
	case  13:
		channel = ADC2_GPIO13_CHANNEL;
		adc_unit = ADC_UNIT_2;
		break;
	case  14:
		channel = ADC2_GPIO14_CHANNEL;
		adc_unit = ADC_UNIT_2;
		break;
	case  15:
		channel = ADC2_GPIO15_CHANNEL;
		adc_unit = ADC_UNIT_2;
		break;
	case  25:
		channel = ADC2_GPIO25_CHANNEL;
		adc_unit = ADC_UNIT_2;
		break;
	case  26:
		channel = ADC2_GPIO26_CHANNEL;
		adc_unit = ADC_UNIT_2;
		break;
	case  27:
		channel = ADC2_GPIO27_CHANNEL;
		adc_unit = ADC_UNIT_2;
		break;
	case  36:
		channel = ADC1_GPIO36_CHANNEL;
		adc_unit = ADC_UNIT_1;
		break;
	case  37:
		channel = ADC1_GPIO37_CHANNEL;
		adc_unit = ADC_UNIT_1;
		break;
	case  38:
		channel = ADC1_GPIO38_CHANNEL;
		adc_unit = ADC_UNIT_1;
		break;
	case  39:
		channel = ADC1_GPIO39_CHANNEL;
		adc_unit = ADC_UNIT_1;
		break;
	case  32:
		channel = ADC1_GPIO32_CHANNEL;
		adc_unit = ADC_UNIT_1;
		break;
	case  33:
		channel = ADC1_GPIO33_CHANNEL;
		adc_unit = ADC_UNIT_1;
		break;
	case  34:
		channel = ADC1_GPIO34_CHANNEL;
		adc_unit = ADC_UNIT_1;
		break;
	case  35:
		channel = ADC1_GPIO35_CHANNEL;
		adc_unit = ADC_UNIT_1;
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

	int raw;
	if (ADC_UNIT_1 == adc_unit) {
		DbgR (adc1_config_channel_atten(channel, adc_atten));
		raw = adc1_get_raw(channel);
	} else {
		DbgR (adc2_config_channel_atten(channel, adc_atten));
		DbgR (adc2_get_raw(channel, adc_width, &raw));
	}

	esp_adc_cal_characteristics_t cal;
	esp_adc_cal_characterize(adc_unit, adc_atten, adc_width, /*vref=*/1100, &cal);

	int mV = esp_adc_cal_raw_to_voltage((uint32_t)raw, &cal);

	*adc = mV / 1000. * divider;

	return ESP_OK;
}

