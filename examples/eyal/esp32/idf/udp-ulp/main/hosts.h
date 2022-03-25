#ifndef MY_HOSTS_H
#define MY_HOSTS_H

// Define module specific setup

#include "config.h"

#if   ESP_32a == MY_HOST	// esp-32a
#define READ_BME280		1	// enable if you have one connected
#define READ_DS18B20		1	// enable if you have one connected
#define BAT_VOLTAGE		5.0	// reported fake when not read
#define ADC_VREF		1130	// measured

#elif ESP_32b == MY_HOST	// esp-32b
#define READ_BME280		0	// enable if you have one connected

#define READ_DS18B20		1	// enable if you have one connected
#define ROM_ID			rom_id
static uint8_t rom_id[][8] = {
	{  40, 255,  92, 161,  80,  24,   2, 135},
//	{  40, 255,   2, 251,  80,  24,   1, 145},
//	{  40, 255,  85, 224,  80,  24,   1, 249},
//	{  40, 255,  51, 218,  80,  24,   1,  39},

	{   0,   0,   0,   0,   0,   0,   0,   0}
};

#define BAT_VOLTAGE		3.8	// reported fake when not read
#define ADC_VREF		1094	// measured when Vdd=3.313v
#undef VDD_DIVIDER
#define VDD_DIVIDER		(2*1.016)
#undef BAT_DIVIDER
#define BAT_DIVIDER		2.09	// measured

#elif ESP_32c == MY_HOST	// esp-32c
#define READ_BME280		0	// enable if you have one connected
#define READ_DS18B20		1	// enable if you have one connected
#define BAT_VOLTAGE		3.8	// reported fake when not read
#define ADC_VREF		1113	// measured when Vdd=3.272v
//#define V1_PIN		34	// resistive moisture sensor
#define V2_PIN			35	// capacitive moisture sensor
#define POWER2_PIN		26
#define POWER_DELAY		100	// ms delay after power on

#elif ESP_32d == MY_HOST	// esp-32d LOIN32
#define READ_BME280		0	// enable if you have one connected
#define READ_DS18B20		1	// enable if you have one connected
#define ROM_ID			rom_id
static uint8_t rom_id[][8] = {
//	{  40, 255,  92, 161,  80,  24,   2, 135},	// used by esp-32b
	{  40, 255,   2, 251,  80,  24,   1, 145},
	{  40, 255,  85, 224,  80,  24,   1, 249},
	{  40, 255,  51, 218,  80,  24,   1,  39},

	{   0,   0,   0,   0,   0,   0,   0,   0}
};

//#define HALL1_PIN		34	// raingauge (same as V1_PIN)	// DEBUG
#define BAT_VOLTAGE		3.8	// reported fake when not read
#define ADC_VREF		1113	// measured when Vdd=3.272v
#define SLEEP_S			10	// DEBUG

#elif ESP_32e == MY_HOST	// esp-32e MIN132
#define READ_BME280		0	// enable if you have one connected
#define READ_DS18B20		0	// enable if you have one connected
#undef  VDD_PIN
#undef  BAT_PIN
#define BAT_VOLTAGE		3.8	// reported fake when not read
#define ADC_VREF		1113	// measured when Vdd=3.272v
#undef DBG_PIN				// GPIO15 not exported

#elif ESP_32f == MY_HOST	// esp-32f LOLIN32
#define READ_BME280		0	// enable if you have one connected
#define READ_DS18B20		1	// enable if you have one connected
#define HALL1_PIN		34	// raingauge (same as V1_PIN)
#define BAT_VOLTAGE		3.8	// reported fake when not read
#define ADC_VREF		1113	// measured when Vdd=3.272v
#define ROM_ID			rom_id
static uint8_t rom_id[][8] = {
	{  40, 220,   1, 120,   6,   0,   0,  15},

	{   0,   0,   0,   0,   0,   0,   0,   0}
};

#elif ESP_32g == MY_HOST	// esp-32g
#define READ_BME280		0	// enable if you have one connected
#define READ_DS18B20		0	// enable if you have one connected
#undef  VDD_PIN
#define VDD_PIN			36	// undef to disable
#undef  VDD_DIVIDER
#define VDD_DIVIDER		 2	// 1m/(1m+1m)
#undef  BAT_PIN
#define BAT_PIN			39
#undef  BAT_DIVIDER
#define BAT_DIVIDER		 2	// 1m/(1m+1m)
#define HALL1_PIN		34	// flow sensor 1
#define HALL2_PIN		35	// flow sensor 2
#define ADC_VREF		1000	// measured when Vdd=3.330v

#elif ESP_32h == MY_HOST	// esp-32h LOLIN32
#define READ_BME280		0	// enable if you have one connected
#define READ_DS18B20		0	// enable if you have one connected
#undef  VDD_PIN
#define VDD_PIN			36	// VP undef to disable
#undef  BAT_PIN
#define BAT_PIN			39	// VN undef to disable
#define HALL1_PIN		34	// raingauge
//#define HALL2_PIN		35	// flow sensor
#define BAT_VOLTAGE		3.8	// reported fake when not read
#define ADC_VREF		1113	// measured when Vdd=3.272v

#elif ESP_32i == MY_HOST	// esp-32i LOLIN32
#undef  VDD_PIN
#define VDD_PIN			36	// VP
#undef  BAT_PIN
#define BAT_PIN			39	// VN
#define HALL1_PIN		34	// flow sensor 1
#define HALL2_PIN		35	// flow sensor 2
#define BAT_VOLTAGE		3.8	// reported fake when not read
#define ADC_VREF		1100	// measured when Vdd=3.272v

#elif ESP_32k == MY_HOST	// esp-32k LOLIN32
#define READ_BME280		0	// enable if you have one connected
#define READ_DS18B20		0	// enable if you have one connected
#undef  VDD_PIN
#define VDD_PIN			36	// VP
#undef  BAT_PIN				// no BAT
#define BAT_PIN			-1	// copy VDD to BAT (no LDO)
#define BAT_VOLTAGE		3.33	// LiFePO4, reported fake when not read
#define VDD_VOLTAGE		BAT_VOLTAGE	// no LDO
#define ADC_VREF		1113	// measured when Vdd=3.272v
#define SLEEP_S			10	// 10s when testing
#define HALL1_PIN		34
#define HALL2_PIN		35
#define SHOW_PULSES		1	// 1=activate ULP anyway
#undef DBG_PIN				// force logging
#undef WIFI_GRACE_MS

#else
#error unknown host MY_HOST
#endif

#ifndef VDD_VOLTAGE
#define	VDD_VOLTAGE		3.3	// from LDO
#endif

#ifndef WIFI_GRACE_MS
#define WIFI_GRACE_MS		0	// time to wait before deep sleep to drain wifi tx
#endif

#ifndef SLEEP_S
#define SLEEP_S			60	// seconds, default
#endif

#ifndef ACTION
#define ACTION			"store"
#endif

#ifndef DBG_PIN
#define DBG_PIN			-1
#endif

#ifndef SHOW_PULSES
#if defined(HALL1_PIN) || defined(HALL2_PIN)
#define SHOW_PULSES		1
#define SHOW_HALL_DEBUG			// while testing
#else
#define SHOW_PULSES		0
#endif
#endif // SHOW_PULSES

#endif // MY_HOSTS_H

