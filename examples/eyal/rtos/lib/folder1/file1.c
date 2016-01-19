#include "esp_common.h"
#include "user_config.h"

char *
ffp(int res, int32 v)	// format int as fixed point
{
	static const uint32	f[] =
		{1, 10, 100, 1000, 10000, 100000, 1000000};
	static char	buf[13];	// "-1234567.890"

	if (res >= 1 && res <= 6) {
		char		*sign;
		uint32		d;
		char		fmt[10];	// "%s%d.%0nd"

		if (v < 0) {
			sign = "-";
			v = -v;
		} else
			sign = "";

		d = f[res];
		snprintf(fmt, sizeof(fmt), "%%s%%d.%%0%dd", res);
		snprintf(buf, sizeof(buf), fmt, sign, v/d, v%d);
	} else 
		snprintf(buf, sizeof(buf), "%d", v);

	return(buf);
}

uint32
time_now(void)
{
	return (system_get_time());
}

char *
time_now_f(void)
{
	return (ffp(6, system_get_time()));
}

uint16
read_tout(int unused)
{
	return (system_adc_read() * 1000/1024);	// fp3
}

uint16
read_vdd(void)
{
	return (readvdd33() * 1000/1024);		// fp3
}

uint8
set_cpu_freq(uint8 freq)
{
	switch (freq) {
	case 160:
		REG_SET_BIT(0x3ff00014, BIT(0));
		system_update_cpu_freq(freq);
		break;
	case 80:
		REG_CLR_BIT(0x3ff00014,  BIT(0));
		system_update_cpu_freq(freq);
		break;
	default:
		break;	// do nothing
	}
	return (system_get_cpu_freq());
}

