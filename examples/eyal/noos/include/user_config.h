#ifndef __USER_CONFIG_H__
#define __USER_CONFIG_H__

#define BUILD_DATE	"noos-20160127-1540"

#include "esp_common.h"

#define logPrintf(...)	// disable log messages
#ifndef logPrintf
#define logPrintf(...) \
do { \
	os_printf(">>> %s ", time_now_f()); \
	os_printf(__VA_ARGS__); \
} while (0)
#endif

#define errPrintf(...) \
do { \
	os_printf("### %s ", time_now_f()); \
	os_printf(__VA_ARGS__); \
} while (0)

typedef struct {
	uint8		clientMAC[6];
	char *		clientID;
	uint8		clientIP[4];
	uint8		gateway[4];
	uint8		netmask[4];
	uint8		udp_grace_ms;
	uint8		magic_pin;
	uint16		sleep_time;
	float		sleep_rate;
	float		adc_factor;
	float		vdd_factor;
	char *		read_device;
	uint8		i2c_SCL;
	uint8		i2c_SDA;
	uint8		ow_pin;
	uint8		(*init_func) (void);
	uint8		ow_addrs[][8];
} env_t;

/* ds18b20.c */
#define BAD_RET		0x7fffffff
extern uint8		ds18b20_setup(uint8 ow_pin);
extern sint32		ds18b20_read(const uint8 *ow_addr);

/* env.c */
extern const env_t	*env;
extern int		setup_env (void);

/* file2.c is empty */

/* file3.c is empty */

/* gpio.c */
extern uint8_t const	gpio_num[];

/* utils.c */
extern char		*ffp(uint8 res, sint32 v);
extern uint32		time_now(void);
extern char *		time_now_f(void);
extern uint16		read_tout(int unused);
extern uint16		read_vdd(void);
extern uint8		set_cpu_freq(uint8 freq);
extern void		pin_config(uint8 pin, uint8 dir, uint8 v);
extern void		pin_output_set(uint8 pin, uint8 v);

#endif

