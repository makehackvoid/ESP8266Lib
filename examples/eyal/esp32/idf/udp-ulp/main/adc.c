/* ADC reading Example

   This example code is in the Public Domain (or CC0 licensed, at your option.)

   Unless required by applicable law or agreed to in writing, this
   software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
   CONDITIONS OF ANY KIND, either express or implied.
*/

#include "udp.h"
#include "adc.h"

#include "soc/adc_channel.h"
#include "driver/adc.h"
#include "esp_adc_cal.h"

static adc_bits_width_t adc_width = ADC_WIDTH_12Bit;
static int adc_vref = 1100;	// set at init time

esp_err_t adc_init (int width, int vref)
{
	adc_power_acquire();

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

esp_err_t adc_read (float *adc_v, uint8_t adc_gpio, int atten, float divider)
{
	adc1_channel_t adc_channel;
	adc_unit_t adc_unit;
	adc_atten_t adc_atten;
	int adc_raw;
	esp_adc_cal_characteristics_t adc_cal;

	*adc_v = 0.0;

	switch (adc_gpio) {
	case  0:
		adc_channel = ADC2_GPIO0_CHANNEL;	// = ADC2_CHANNEL_1
		adc_unit = ADC_UNIT_2;
		break;
	case  2:
		adc_channel = ADC2_GPIO2_CHANNEL;	// = ADC2_CHANNEL_2
		adc_unit = ADC_UNIT_2;
		break;
	case  4:
		adc_channel = ADC2_GPIO4_CHANNEL;	// = ADC2_CHANNEL_0
		adc_unit = ADC_UNIT_2;
		break;
	case  12:
		adc_channel = ADC2_GPIO12_CHANNEL;	// = ADC2_CHANNEL_5
		adc_unit = ADC_UNIT_2;
		break;
	case  13:
		adc_channel = ADC2_GPIO13_CHANNEL;	// = ADC2_CHANNEL_4
		adc_unit = ADC_UNIT_2;
		break;
	case  14:
		adc_channel = ADC2_GPIO14_CHANNEL;	// = ADC2_CHANNEL_6
		adc_unit = ADC_UNIT_2;
		break;
	case  15:
		adc_channel = ADC2_GPIO15_CHANNEL;	// = ADC2_CHANNEL_3
		adc_unit = ADC_UNIT_2;
		break;
	case  25:
		adc_channel = ADC2_GPIO25_CHANNEL;	// = ADC2_CHANNEL_8
		adc_unit = ADC_UNIT_2;
		break;
	case  26:
		adc_channel = ADC2_GPIO26_CHANNEL;	// = ADC2_CHANNEL_9
		adc_unit = ADC_UNIT_2;
		break;
	case  27:
		adc_channel = ADC2_GPIO27_CHANNEL;	// = ADC2_CHANNEL_7
		adc_unit = ADC_UNIT_2;
		break;
	case  36:
		adc_channel = ADC1_GPIO36_CHANNEL;	// = ADC1_CHANNEL_0
		adc_unit = ADC_UNIT_1;
		break;
	case  37:
		adc_channel = ADC1_GPIO37_CHANNEL;	// = ADC1_CHANNEL_1
		adc_unit = ADC_UNIT_1;
		break;
	case  38:
		adc_channel = ADC1_GPIO38_CHANNEL;	// = ADC1_CHANNEL_2
		adc_unit = ADC_UNIT_1;
		break;
	case  39:
		adc_channel = ADC1_GPIO39_CHANNEL;	// = ADC1_CHANNEL_3
		adc_unit = ADC_UNIT_1;
		break;
	case  32:
		adc_channel = ADC1_GPIO32_CHANNEL;	// = ADC1_CHANNEL_4
		adc_unit = ADC_UNIT_1;
		break;
	case  33:
		adc_channel = ADC1_GPIO33_CHANNEL;	// = ADC1_CHANNEL_5
		adc_unit = ADC_UNIT_1;
		break;
	case  34:
		adc_channel = ADC1_GPIO34_CHANNEL;	// = ADC1_CHANNEL_6
		adc_unit = ADC_UNIT_1;
		break;
	case  35:
		adc_channel = ADC1_GPIO35_CHANNEL;	// = ADC1_CHANNEL_7
		adc_unit = ADC_UNIT_1;
		break;
	default:
		LogR (ESP_FAIL, "bad ADC GPIO pin %d", adc_gpio);
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

	if (ADC_UNIT_1 == adc_unit) {
		DbgR (adc1_config_channel_atten(adc_channel, adc_atten));
		adc_raw = adc1_get_raw(adc_channel);
	} else {
		DbgR (adc2_config_channel_atten(adc_channel, adc_atten));
		DbgR (adc2_get_raw(adc_channel, adc_width, &adc_raw));
	}

	esp_adc_cal_value_t val_type = esp_adc_cal_characterize(adc_unit, adc_atten, adc_width,
		adc_vref, &adc_cal);

	if (ESP_ADC_CAL_VAL_EFUSE_VREF == val_type)
		Log("Vref type: eFuse");
	else if (ESP_ADC_CAL_VAL_EFUSE_TP == val_type)
		Log("Vref type: Two Points");
	else
		Log("Vref type: user default %d", adc_vref);

	int mV = esp_adc_cal_raw_to_voltage((uint32_t)adc_raw, &adc_cal);

	*adc_v = mV / 1000. * divider;

	return ESP_OK;
}

esp_err_t adc_term (void)
{
	adc_power_release();
	return ESP_OK;
}

