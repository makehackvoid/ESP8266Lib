#include "esp_common.h"
#include "user_config.h"
#include "gpio.h"

#if 000
void
delay_us(uint32 us)
{
	int	i;

	i = 0;
	while (us >= 65535) {
		os_delay_us(65535);
		us -= 65535;
		if (0 == ++i%16)	// about 1 per sec
			system_soft_wdt_feed();
	}
	if (us > 0)
		os_delay_us((uint16)us);
}

void
print_mac(uint8 mode)
{
	uint8	mac[6];

	wifi_get_macaddr(mode, mac);
	printf("%s MAC = %2x:%2x:%2x:%2x:%2x:%2x\n",
		(STATION_IF == mode ? "STA" : "AP "),
		mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
}

void
print_ip(char *title, uint8 *ip)
{
	printf("%s %u.%u.%u.%u\n", title, ip[0], ip[1], ip[2], ip[3]);
}

void
print_ip_info(uint8 mode)
{
	struct ip_info	pTempIp;

	wifi_get_ip_info(mode, &pTempIp);
	if (0 == pTempIp.ip.addr)
		printf("AP  IP not available\n");
	else {
		print_ip("AP  IP", (void *)&pTempIp.ip);
		print_ip("AP  NM", (void *)&pTempIp.netmask);
		print_ip("AP  GW", (void *)&pTempIp.gw);
	}
}

void
pin_config(int pin, int dir)
{
	uint16	mask = 1<<pin;
	
	PIN_FUNC_SELECT(GPIO_PIN_REG(pin),			// configure
		(mask & (BIT0|BIT2|BIT4|BIT5)) ? 0 : 3);
	gpio_output_set(dir<<pin, (!dir)<<pin, mask, 0);	// enable
}
#endif
