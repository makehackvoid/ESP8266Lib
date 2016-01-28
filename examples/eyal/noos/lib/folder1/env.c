#include "user_config.h"

#define OW_EOL	{255,255,255,255,255,255,255,255}

static const env_t env_esp_07b = {
	{0x18,0xFE,0x34,0xA2,0x6D,0x54},	// clientMAC
	"esp-07b",				// clientID
	{192,168,2,38},				// clientIP
	{192,168,2,7},				// gateway
	{255,255,255,0},			// netmask
	30,					// udp_grace_ms
	5,					// magic_pin (GPIO5)
	60,					// sleep_time
	1.02335,				// sleep_rate
	11.8,					// adc_factor
	0.957,					// vdd_factor
	"ds18b20",				// read_device
	-1, -1,					// i2c_SCL, i2c_SDA
	4,					// ow_pin
	NULL,					// init_func
	{					// ow_addrs
		{ 40,255,157,227,  0, 21,  3, 35},	// #1 low
		{ 40,255, 57,229,  0, 21,  3,  6},	// #2 mid
		{ 40,255,205, 76, 21, 21,  2,164},	// #3 high
		{ 40,255, 93, 29, 21, 21,  2, 68},	// #4 south
		OW_EOL
	}
};

static const env_t env_esp_12f = {
	{0x18,0xFE,0x34,0xF2,0x9C,0x46},
	"esp-12f",
	{192,168,2,47},
	{192,168,2,7},
	{255,255,255,0},
	30,
	5,
	60,
	1.017,			// time
	15.6,			// adc
	1,			// vdd
	"ds18b20",
	-1, -1,
	4,
	NULL,
	{
		{ 40, 24,158,118,  6,  0,  0,129},
		OW_EOL
	}
};

static const env_t env_esp_witty = {
	{0x5C,0xCF,0x7F,0x12,0x6B,0x24},
	"esp-witty",
	{192,168,2,48},
	{192,168,2,7},
	{255,255,255,0},
	30,
	5,
	60,
	1,			// time
	11,			// adc
	1,			// vdd
	"ds18b20",
	-1, -1,
	4,
	NULL,
	{
		OW_EOL
	}
};

static const env_t env_esp_201 = {
	{0x18,0xFE,0x34,0xA0,0xE1,0x1C},
	"esp-201",
	{192,168,2,34},
	{192,168,2,7},
	{255,255,255,0},
	30,
	5,
	60,
	1.0409,			// time
	12.1,			// adc
	0.955,			// vdd
	"ds18b20",
	-1, -1,
	4,
	NULL,
	{
		{ 40, 24,158,118,  6,  0,  0,129},
		OW_EOL
	}
};

static const env_t env_esp_test = {
	{0x00,0x00,0x00,0x00,0x00,0x00},
	"esp-test",
	{192,168,2,99},
	{192,168,2,7},
	{255,255,255,0},
	30,
	5,
	60,
	1.,			// time
	11,			// adc
	1,			// vdd
	"ds18b20",
	-1, -1,
	4,
	NULL,
	{
		OW_EOL
	}
};

static const env_t *envs[] = {
	&env_esp_07b,
	&env_esp_12f,
	&env_esp_witty,
	&env_esp_201,
	NULL
};

const env_t	*env = NULL;

int
setup_env (void)
{
	uint8		mac[6];
	int		i;

	wifi_get_macaddr(STATION_IF, mac);

	for (i = 0;; ++i) {
		env = envs[i];
		if (NULL == env) {
//			os_printf("setup_env failed\n");
			env = &env_esp_test;
			return 0;	// failure
		}
		if (!memcmp (mac, env->clientMAC, sizeof(mac)))
			break;	// success
	}

	if (env == &env_esp_witty) {	// turn off colour LED
		pin_config(12, PLATFORM_GPIO_OUTPUT, PLATFORM_GPIO_LOW);
		pin_config(13, PLATFORM_GPIO_OUTPUT, PLATFORM_GPIO_LOW);
		pin_config(15, PLATFORM_GPIO_OUTPUT, PLATFORM_GPIO_LOW);
	}

	return 1;
}
