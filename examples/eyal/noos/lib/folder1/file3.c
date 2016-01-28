#include "user_config.h"

#if 000
static void
blink_led(void)
{
	int	i;
	uint16	pins;

	pin_config(12, GPIO_DIR_OUT);
	pin_config(13, GPIO_DIR_OUT);
	pin_config(15, GPIO_DIR_OUT);
	pins = BIT12|BIT13|BIT15;

	for (i = 1; i < 8; ++i) {			// 7 colours
		uint16	mask = ((i&4)<<(12-2)) | ((i&2)<<(13-1)) | ((i&1)<<(15-0));
		printf(" %d", i);
		gpio_output_set(mask, (~mask)&pins, 0, 0);
		delay_us(250000);
		gpio_output_set(0,    mask, 0, 0);	// all off
		delay_us(250000);
	}
	printf("\n");

	printf("tmr now = %ss\n", time_now_f());
	printf("sleeping 2s\n");
	system_deep_sleep(2*1000000);
	vTaskDelete(NULL);
}
#endif

#if 000
static void
print_stuff() {
	printf("tmr now = %ss\n", time_now_f());

	printf("SDK version: %s\n", system_get_sdk_version());
	printf("APP version: %s built: %s %s\n", BUILD_DATE, __DATE__, __TIME__);

	printf("CPU freq was %d\n", system_get_cpu_freq());
	printf("CPU freq = %d\n", set_cpu_freq(160));
	printf("tmr now = %ss\n", time_now_f());

	printf("tout    = %sV\n", ffp(3, read_tout(0)*123/10));
	printf("vdd     = %sV\n", ffp(3, read_vdd()));

	print_mac(STATION_IF);
	print_mac(SOFTAP_IF);

	print_ip_info(SOFTAP_IF);
	print_ip_info(STATION_IF);

	printf("tmr now = %ss\n", time_now_f());
	printf("sleeping 2s\n");
	system_deep_sleep(2*1000000);
	vTaskDelete(NULL);
}
#endif
