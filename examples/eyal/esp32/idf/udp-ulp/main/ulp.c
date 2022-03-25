/* mostly taken from the ESP_IDF example
*/

#include "udp.h"
#include "ulp.h"

#include "driver/gpio.h"
#include "driver/rtc_io.h"
#include "esp32/ulp.h"
#include <esp_sleep.h>
#include "ulp_main.h"

extern const uint8_t ulp_main_bin_start[] asm("_binary_ulp_main_bin_start");
extern const uint8_t ulp_main_bin_end[]   asm("_binary_ulp_main_bin_end");

static void ulp_setup_gpio (int gpio_num, uint32_t *ulp_gpio)
{
    if (gpio_num < 0) {
	*ulp_gpio = -1;
	return;
    }
    assert(rtc_gpio_is_valid_gpio(gpio_num) && "GPIO used for pulse counting must be an RTC IO");
    *ulp_gpio = rtc_io_number_get(gpio_num);	// tell ULP

    /* Initialize selected GPIO as RTC IO, enable input, disable pullup and pulldown */
    rtc_gpio_init(gpio_num);
    rtc_gpio_set_direction(gpio_num, RTC_GPIO_MODE_INPUT_ONLY);
    rtc_gpio_pulldown_dis(gpio_num);
    rtc_gpio_pullup_dis(gpio_num);
    rtc_gpio_hold_en(gpio_num);
}


void ulp_init_program(void)
{
//Log ("init_ulp_program");
    esp_err_t err = ulp_load_binary(0, ulp_main_bin_start,
            (ulp_main_bin_end - ulp_main_bin_start) / sizeof(uint32_t));
    ESP_ERROR_CHECK(err);

    /* Initialize some variables used by ULP program.
     * Each 'ulp_xyz' variable corresponds to 'xyz' variable in the ULP program.
     * These variables are declared in an auto generated header file,
     * 'ulp_main.h', name of this file is defined in component.mk as ULP_APP_NAME.
     * These variables are located in RTC_SLOW_MEM and can be accessed both by the
     * ULP and the main CPUs.
     *
     * Note that the ULP reads only the lower 16 bits of these variables.
     */

    ulp_setup_gpio (p1_pin, &ulp_p1_pin);
    ulp_setup_gpio (p2_pin, &ulp_p2_pin);

    /* Disconnect GPIO12 and GPIO15 to remove current drain through
     * pullup/pulldown resistors.
     * GPIO12 may be pulled high to select flash voltage.
     */
//  rtc_gpio_isolate(GPIO_NUM_12);
//  rtc_gpio_isolate(GPIO_NUM_15);

    esp_deep_sleep_disable_rom_logging(); // suppress boot messages

    /* Set ULP wake up period to T = 20ms.
     * Minimum pulse width has to be T * (ulp_debounce_counter + 1) = 80ms.
     */
    ulp_set_wakeup_period(0, 200);

    /* Start the program */
    err = ulp_run(&ulp_entry - RTC_SLOW_MEM);
    ESP_ERROR_CHECK(err);
}

static uint32_t *ulp_get_count (int counter)
{
	uint32_t	*count;

	switch (counter) {
	case 0:
		count = (uint32_t *)&ulp_timer;
		break;
	case 1:
		count = (uint32_t *)&ulp_p1_count;
		break;
	case 2:
		count = (uint32_t *)&ulp_p2_count;
		break;
	case 11:
		count = (uint32_t *)&ulp_p1_noise;
		break;
	case 12:
		count = (uint32_t *)&ulp_p2_noise;
		break;
	case 13:
		count = (uint32_t *)&ulp_longest;
		break;
	default:
		Log ("%s invalid argument %d", __FUNCTION__, counter);
		count = NULL;
		break;
	}

	return count;
}

uint32_t ulp_get_count_16(int counter)
{
	uint32_t	*count;
	uint32_t	result;

	count = ulp_get_count (counter);
	if (NULL == count)
		result = 0;
	else {
		result = (uint32_t)(count[0] & UINT16_MAX);
		if (0 == counter) count[0]  = 0;
	}
	return result;
}

uint32_t ulp_get_count_32(int counter)
{
	uint32_t	*count;
	uint32_t	result;

	count = ulp_get_count (counter);
	if (NULL == count)
		result = 0;
	else {
		uint32_t lcount[2];
		memcpy (lcount, count, sizeof(lcount));
		result =   (uint32_t)(lcount[0] & UINT16_MAX)
			+ (uint32_t)((lcount[1] & UINT16_MAX) << 16);
		if (0 == counter) memset (count, 0, sizeof(lcount));
	}
	return result;
}

