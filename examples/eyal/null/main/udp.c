#include "ulp.h"

#include <freertos/FreeRTOS.h>
#include <freertos/event_groups.h>

#include <esp32/rom/rtc.h>
#include <soc/rtc.h>
#include <esp_sleep.h>
#include "driver/rtc_io.h"

#define RUN_ULP				// undef to disable
#define SLEEP_S			 5	// seconds, default
#define DELAY_MS		 0	// 0 to disable

void
app_main ()
{
	WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0);	//disable brownout detector

#ifdef RUN_ULP
	if (rtc_get_reset_reason(0) != DEEPSLEEP_RESET)
		ulp_init_program();
#endif

	esp_sleep_pd_config(ESP_PD_DOMAIN_RTC_PERIPH, ESP_PD_OPTION_AUTO);
	esp_sleep_pd_config(ESP_PD_DOMAIN_RTC_SLOW_MEM, ESP_PD_OPTION_AUTO);
	esp_sleep_pd_config(ESP_PD_DOMAIN_RTC_FAST_MEM, ESP_PD_OPTION_AUTO);
	esp_sleep_pd_config(ESP_PD_DOMAIN_XTAL, ESP_PD_OPTION_AUTO);

//	gpio_pullup_en(GPIO_NUM_0);
//	rtc_gpio_isolate(GPIO_NUM_0);

//	rtc_gpio_isolate(GPIO_NUM_2);

//	gpio_pullup_en(GPIO_NUM_12);
//	rtc_gpio_isolate(GPIO_NUM_12);

//  	gpio_pullup_en(GPIO_NUM_15);
//	rtc_gpio_isolate(GPIO_NUM_15);

#if DELAY
	vTaskDelay(DELAY_MS / portTICK_PERIOD_MS);
#endif

	esp_deep_sleep(1000000*SLEEP_S);
}

