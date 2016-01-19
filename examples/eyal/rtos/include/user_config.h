#ifndef __USER_CONFIG_H__
#define __USER_CONFIG_H__

#define BUILD_DATE	"rtos-20160120-1048"

// GPIO direction values

#define GPIO_DIR_OUT 1
#define GPIO_DIR_IN  0

#define logPrintf(...) printf(__VA_ARGS__)
//#define logPrintf(...)

typedef struct {
	uint8		clientMAC[6];
	char *		clientID;
	uint8		clientIP[4];
	uint8		gateway[4];
	uint8		netmask[4];
	int		udp_grace_ms;
	int		magic_pin;
	int		sleep_time;
	float		sleep_rate;
	float		adc_factor;
	float		vdd_factor;
	char *		read_device;
	int		i2c_SCL;
	int		i2c_SDA;
	int		ow_pin;
	int		(*init_func) (void);
	uint8		ow_addrs[][8];
} env_t;

extern env_t	*env;
extern int setup_env (void);

#endif

