/* UDP reporting Example

   This example code is in the Public Domain (or CC0 licensed, at your option.)

   Unless required by applicable law or agreed to in writing, this
   software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
   CONDITIONS OF ANY KIND, either express or implied.
*/

#include "udp.h"
#include "wifi.h"
#include "ulp.h"

#include <esp_log.h>
#include <esp32/rom/rtc.h>
#include <esp32/rom/uart.h>	// uart_tx_wait_idle()
#include <soc/efuse_reg.h>	// needed by getChip*()
#include <soc/rtc.h>
#include <esp32/clk.h>
#include <esp_sleep.h>
#include "driver/rtc_io.h"

#include "ulp_main.h"		// DEBUG

#ifndef MY_NAME
#define MY_NAME			"test"
#endif

#define USE_WIFI
#define WIFI_GRACE_MS		30	// time to wait before deep sleep to drain wifi tx

#define PRINT_MSG		1	// 1= print sent message if logging is off
#define SHOW_CLOCKS		0	// include "clocks=..."
#define SHOW_TIMERS		0	// include "timers=..."

#define APP_CPU_AFFINITY	1	// 0, 1 or tskNO_AFFINITY

// tskIDLE_PRIORITY + n
// configMAX_PRIORITIES - n
#define APP_TASK_PRIORITY	(tskIDLE_PRIORITY+5)
#define APP_TASK_STACK		(8*1024)

#define I2C_SCL			22	// i2c
#define I2C_SDA			21	// i2c
#define OUT_PIN			19	// OUT mark program steps (debug)	[-ve to disable]
#define OW_PIN			18	// IO  ow
#define ERROR_PIN		17	// OUT indicate a failure (debug)	[-ve to disable]
#define TOGGLE_PIN		16	// IN  pull low to enable toggle()	[-ve to disable]
#define DBG_PIN			15	// IN  pull low to enable Log()		[-ve to disable]

			// adc channel 1 pins are 32-39
#define VDD_PIN			32	// undef to disable
#define VDD_DIVIDER		2	// 1m/(1m+1m)
#define VDD_ATTEN		11	// 11db, 2.45v max

#define BAT_PIN			33	// undef to disable, -1 if same as VDD
#define BAT_DIVIDER		2	// 1m/(1m+1m)
#define BAT_ATTEN		11	// 11db, 2.45v max

//#define V1_PIN		NN	// define to enable
#define V1_DIVIDER		1	// no resistor network
#define V1_ATTEN		11	// 11db, 2.45v max

//#define V2_PIN		NN	// define to enable
#define V2_DIVIDER		1	// no resistor network
#define V2_ATTEN		11	// 11db, 2.45v max

#define READ_VOLTAGES_EARLY		// better adc readings before starting wifi

#undef  POWER1_PIN			// 25 OUT drive external devices		[undef to disable]
#undef  POWER2_PIN			// 26 OUT drive external devices		[undef to disable]
#undef	POWER_DELAY			// ms delay after power on			[0 to disable]

#define READ_TSENS		0	// read esp32 temperature sensor

#include "hosts.h"			// module specific setup

#if (defined(VDD_PIN) || defined(BAT_PIN) || defined(V1_PIN) || defined(V2_PIN))
#define READ_ADC		1
#include "adc.h"
#else
#define READ_ADC		0
#endif

#define ADC_UNDEF		999

#ifndef ADC_DAMP
#define ADC_DAMP		10.0			//      20.0 10.0  1.0
#endif
#define ADC_DAMP_NOW		(1/ADC_DAMP)		// e.g. 0.05  0.1  1.0
#define ADC_DAMP_PREV		(1-ADC_DAMP_NOW)	// e.g. 0.95  0.9  0.0

#if OUT_PIN < 0
#undef TOGGLE_PIN
#define TOGGLE_PIN		-1
#endif

#if READ_BME280
#include "bme280.h"
RTC_DATA_ATTR static int bme280_failures = 0;
#endif

#if READ_DS18B20
#include "ds18b20.h"
RTC_DATA_ATTR static int ds18b20_failures = 0;
#endif

#if READ_TSENS
#include "tsens.h"
#endif

#if SHOW_TIMERS
#include <driver/timer.h>	// timer_get_counter_time_sec()
#endif

int do_log = 1;
ulong time_wifi_us = 0;
int rssi = 0;
int sent = 0;
int retry_count = 0;
bool woke_up = 0;

RTC_DATA_ATTR static int runCount = 0;
RTC_DATA_ATTR static uint64_t sleep_start_us = 0;
RTC_DATA_ATTR static uint64_t sleep_start_ticks = 0;
RTC_DATA_ATTR static uint64_t sleep_length_us = 0;
RTC_DATA_ATTR static uint64_t prev_app_start_us = 0;
RTC_DATA_ATTR static struct timeval wakeup;
RTC_DATA_ATTR static int WiFiFailSoft = 0;
RTC_DATA_ATTR static int WiFiFailHard = 0;
RTC_DATA_ATTR        int channel = 0;
RTC_DATA_ATTR static int TempFailSoft = 0;
RTC_DATA_ATTR static int TempFailHard = 0;
#if WIFI_GRACE_MS > 0
RTC_DATA_ATTR static int lastGrace = 0;
#endif
RTC_DATA_ATTR static uint64_t timeLast = 0;
RTC_DATA_ATTR static uint64_t timeTotal = 0;
RTC_DATA_ATTR static float vdd = ADC_UNDEF;	// indicate no prev value for damping
RTC_DATA_ATTR static float bat = ADC_UNDEF;	// indicate no prev value for damping
RTC_DATA_ATTR static float  v1 = ADC_UNDEF;	// indicate no prev value for damping
RTC_DATA_ATTR static float  v2 = ADC_UNDEF;	// indicate no prev value for damping

int p1_pin = -1;	// used in ulp.c
int p2_pin = -1;

static int do_toggle = 0;
static struct timeval app_start;
static uint64_t app_start_us = 0;
static uint64_t app_start_ticks = 0;
static int wakeup_cause;
static int reset_reason;

#ifdef SHOW_HALL_DEBUG
static uint32_t ulp_loop_count   = 0;
static uint16_t ulp_shortest_noise = 0;
#endif

#if SHOW_CLOCKS
#define system_get_time_64 esp_time_impl_get_time_since_boot
// The following is defined in
//	components/newlib/priv_include/esp_time_impl.h
// so added "REQUIRES newlib" fo main/CMakeLists.txt
#endif

uint64_t gettimeofday_64(void)
{
	struct timeval tv;
	struct timezone tz;
	gettimeofday(&tv, &tz);
	return tv.tv_sec*1000000ULL + tv.tv_usec;

//	struct timespec tp;
//	clock_gettime (CLOCK_REALTIME, &tp);
//	return tp.tv_sec*1000000ULL + tp.tv_nsec/1000ULL;
}

void flush_uart (void)
{
	fflush(stdout);
	uart_tx_wait_idle(CONFIG_ESP_CONSOLE_UART_NUM);
}

static void toggle_setup (void)
{
#if OUT_PIN >= 0
	gpio_pad_select_gpio(OUT_PIN);
	gpio_set_direction(OUT_PIN, GPIO_MODE_OUTPUT);
	gpio_set_level(OUT_PIN, 1);	// start HIGH
#endif
}

static void power_on (void)
{
#ifdef POWER1_PIN
	gpio_pad_select_gpio(POWER1_PIN);
	gpio_set_direction(POWER1_PIN, GPIO_MODE_OUTPUT);
	gpio_set_level(POWER1_PIN, 1);	// turn on power pin
#endif
#ifdef POWER2_PIN
	gpio_pad_select_gpio(POWER2_PIN);
	gpio_set_direction(POWER2_PIN, GPIO_MODE_OUTPUT);
	gpio_set_level(POWER2_PIN, 1);	// turn on power pin
#endif
#if defined(POWER1_PIN) || defined(POWER2_PIN)
#ifndef POWER_DELAY
#define POWER_DELAY	200
#endif
#if POWER_DELAY > 0
	delay_ms (POWER_DELAY);	// allow power pin to ramp up
#endif
#endif
}

static void power_off (void)
{
#ifdef POWER1_PIN
	gpio_set_level(POWER1_PIN, 0);	// turn off power pin
#endif
#ifdef POWER2_PIN
	gpio_set_level(POWER2_PIN, 0);	// turn off power pin
#endif
}

#if USE_DELAY_BUSY
static void delay_us_busy (int us)
{
	uint64_t end = gettimeofday_64() + us;
	while (gettimeofday_64() < end)
		{}
}
#endif

// pin is LOW  during sleep
// pin is HIGH at start
// toggle is 100us: 50us LOW, 50us HIGH (not on final time)
static void toggle_out (int ntimes, int us)
{
#if OUT_PIN >= 0
	if (do_toggle) while (ntimes-- > 0) {
		gpio_set_level(OUT_PIN, 0);
		delay_us (us);
		gpio_set_level(OUT_PIN, 1);
		if (ntimes)
			delay_us (us);
	}
#endif
}

void toggle (int ntimes) {
	toggle_out (ntimes, 50);
}

void toggle_short (int ntimes) {
	toggle_out (ntimes, 2);
}

#if ERROR_PIN >= 0 && (READ_DS18B20 || READ_BME280)
static void toggle_error (void)
{
	gpio_pad_select_gpio(ERROR_PIN);
	gpio_set_direction(ERROR_PIN, GPIO_MODE_OUTPUT);
	gpio_set_level(ERROR_PIN, 1);	// start HIGH
	delay_us (50);
	gpio_set_level(ERROR_PIN, 0);
}
#else
#define toggle_error()
#endif

// time since app start
static void get_time_since_start (struct timeval *now)
{
	gettimeofday (now, NULL);
	if (now->tv_usec < app_start.tv_usec) {
		now->tv_usec += 1000000;
		--now->tv_sec;
	}

	now->tv_sec  -= app_start.tv_sec;
	now->tv_usec -= app_start.tv_usec;
}

// time since wakeup (earlier than app start)
void get_time_since_wakeup (struct timeval *rel, struct timeval *abs)
{
	struct timeval labs;

	if (NULL == abs) {
		abs = &labs;
		gettimeofday (abs, NULL);	// time now
	}

	rel->tv_sec = abs->tv_sec - wakeup.tv_sec;
	if (abs->tv_usec >= wakeup.tv_usec)
		rel->tv_usec = abs->tv_usec - wakeup.tv_usec;
	else {
		--rel->tv_sec;
		rel->tv_usec = (1000000UL + abs->tv_usec) - wakeup.tv_usec;
	}
}

#if 000	// not used
static uint64_t get_time_us (void) {
	return gettimeofday_64() - app_start_us;
}
#endif

#if READ_DS18B20
static esp_err_t ds18b20_temp_start (void)
{
	esp_err_t ret;
	esp_err_t rval;		// return first failure


	rval = ESP_OK;

	DbgR (ds18b20_init (OW_PIN, NULL));

	Dbg (ds18b20_convert (1));
	if (ESP_OK == rval) rval = ret;

	return rval;
}

static esp_err_t ds18b20_temp (uint8_t *rom_id, float *temp)
{
	esp_err_t ret;
	esp_err_t rval;		// return first failure
	uint8_t id[8];

	*temp = 0.0;
	rval = ESP_OK;

if (0 && NULL != rom_id)	// enable for DEBUG to always show IDs
	Log("ds18b20 rom_id: {%4u,%4u,%4u,%4u,%4u,%4u,%4u,%4u}",
		rom_id[0], rom_id[1], rom_id[2], rom_id[3], rom_id[4], rom_id[5], rom_id[6], rom_id[7]);

	DbgR (ds18b20_init (OW_PIN, rom_id));

	if (!woke_up) {		// just powered up
		DbgR (ds18b20_read_id (id));
		Log("ds18b20 ROM id: %02x %02x %02x %02x %02x %02x %02x %02x",
			id[0], id[1], id[2], id[3], id[4], id[5], id[6], id[7]);
		Log("ds18b20 ROM id: {%4d,%4d,%4d,%4d,%4d,%4d,%4d,%4d},",
			id[0], id[1], id[2], id[3], id[4], id[5], id[6], id[7]);
	}

	Dbg (ds18b20_read_temp (temp));
	if (ESP_OK == rval) rval = ret;

	return rval;
}

static esp_err_t ds18b20_temp_end (void)
{
	esp_err_t ret;
	esp_err_t rval;		// return first failure

	rval = ESP_OK;

	DbgR (ds18b20_init (OW_PIN, NULL));	// convert all

	Dbg (ds18b20_convert (0));
	if (ESP_OK == rval) rval = ret;

	Dbg (ds18b20_depower ());
	if (ESP_OK == rval) rval = ret;

	return rval;
}

static float ds18b20_failure_reason = 0;
#endif // READ_DS18B20

#define MAX_TEMPS		8
static int ntemps = 0;
static float temps[MAX_TEMPS];
static char weather[40] = "";
static ulong time_temps_us = 0;
static ulong time_adc_us = 0;

// save first failure in 'rval'
//
#define DbgRval(f) \
do { \
	Dbg (f); \
	if (ESP_OK == rval) rval = ret; \
} while (0)

static esp_err_t read_temps (void)
{
	esp_err_t rval = ESP_OK;	// return first failure

#if READ_DS18B20 || READ_TSENS || READ_BME280
	esp_err_t ret;
	float temp;
	uint64_t time_1_us, time_2_us;

	ntemps = 0;

	time_1_us = gettimeofday_64();

#if READ_DS18B20
	while (ntemps < MAX_TEMPS) {
		uint8_t	*id;
#ifndef ROM_ID
		id = NULL;		// read one sensor
#else
		id = ROM_ID[ntemps];
		if (0 == *id)		// closing entry
			break;
#endif
		if (0 == ntemps && !woke_up)
			ds18b20_temp_start ();

		DbgRval (ds18b20_temp (id, &temp));
		if (ret != ESP_OK || temp >= BAD_TEMP) {
			toggle_error();		// tell DSO
			++ds18b20_failures;
			ds18b20_failure_reason = temp;
			DbgRval (ds18b20_temp (id, &temp));	// one retry
			if (ret != ESP_OK || temp >= BAD_TEMP) {
				toggle_error();		// tell DSO
				++TempFailHard;
				temp = BAD_TEMP;
			} else
				++TempFailSoft;
		}
		temps[ntemps++] = temp;
		if (NULL == id)
			break;
	}
	if (ntemps > 0)
		ds18b20_temp_end ();
#endif // READ_DS18B20

#if READ_TSENS
	if (ntemps < MAX_TEMPS) {
		int tsens;

		DbgRval (tsens_read (&tsens));
		temps[ntemps++] = tsens;
	}
#endif

#if READ_BME280
	{
		float qfe, h, qnh;
		int fail;

		DbgRval (bme280_init(I2C_SDA, I2C_SCL, !woke_up));

		DbgRval (bme280_read (622, &temp, &qfe, &h, &qnh));
		if (ret != ESP_OK || temp >= BAD_TEMP) {
			toggle_error();		// tell DSO
			++TempFailSoft;
			++bme280_failures;
		}

		fail = 0;
		if (       BAD_TEMP <= temp) fail |= 0x01;
		if (BME280_BAD_QFE  == qfe)  fail |= 0x02;
		if (BME280_BAD_HUMI == h)    fail |= 0x04;

		snprintf (weather, sizeof(weather),
			" w=T%.2f,P%.3f,H%.3f,f%x",
			temp, qnh, h, fail);
		if (ntemps < MAX_TEMPS) temps[ntemps++] = temp;
	}
#endif // READ_BME280

	time_2_us = gettimeofday_64();
	time_temps_us = (ulong)(time_2_us - time_1_us);
#else
	time_temps_us = 0;
	rval = ESP_OK;
#endif
	if (0 == ntemps)
		if (ntemps < MAX_TEMPS) temps[ntemps++] = 0;

	return rval;
}

#if READ_ADC
static esp_err_t adc_read_damp (
	float *adc_v,
	uint8_t adc_gpio,
	int atten,
	float divider)
{
	esp_err_t ret;
	esp_err_t rval = ESP_OK;	// return first failure
	float	adc_now;
	float	adc_prev;

	gpio_pad_select_gpio(adc_gpio);
	gpio_set_direction(adc_gpio, GPIO_MODE_INPUT);
	gpio_pulldown_dis (adc_gpio);
	gpio_pullup_dis (adc_gpio);

	DbgRval (adc_read (&adc_now, adc_gpio, atten, divider));
	if (ADC_UNDEF == (adc_prev = *adc_v))
		*adc_v = adc_now;
	else
		*adc_v = ADC_DAMP_PREV*adc_prev + ADC_DAMP_NOW*adc_now;

	return rval;
}
#endif

static esp_err_t read_voltages (void)
{
	esp_err_t ret;
	esp_err_t rval = ESP_OK;	// return first failure
	uint64_t time_1_us, time_2_us;

	flush_uart ();		// avoid uart interruptions

	time_1_us = gettimeofday_64();

#if READ_ADC
	DbgRval (adc_init (12, ADC_VREF));
#endif

#ifdef VDD_PIN
	DbgRval (adc_read_damp (&vdd, VDD_PIN, VDD_ATTEN, VDD_DIVIDER));
#else
	vdd = VDD_VOLTAGE;
#endif

#ifdef BAT_PIN
#if BAT_PIN >=0
	DbgRval (adc_read_damp (&bat, BAT_PIN, BAT_ATTEN, BAT_DIVIDER));
#else
	bat = vdd;
#endif
#else
	bat = BAT_VOLTAGE;
#endif

#ifdef V1_PIN
	DbgRval (adc_read_damp (&v1, V1_PIN, V1_ATTEN, V1_DIVIDER));
#else
	v1 = 0;
#endif

#ifdef V2_PIN
	DbgRval (adc_read_damp (&v2, V2_PIN, V2_ATTEN, V2_DIVIDER));
#else
	v2 = 0;
#endif

#if READ_ADC
	adc_term();
#endif
	time_2_us = gettimeofday_64();

	time_adc_us = (ulong)(time_2_us - time_1_us);

	return rval;
}
#undef DbgRval

#if 000
From include/rom/rtc.h:

typedef enum {
    NO_SLEEP        = 0,
    EXT_EVENT0_TRIG = BIT0,
    EXT_EVENT1_TRIG = BIT1,
    GPIO_TRIG       = BIT2,
    TIMER_EXPIRE    = BIT3,
    SDIO_TRIG       = BIT4,
    MAC_TRIG        = BIT5,
    UART0_TRIG      = BIT6,
    UART1_TRIG      = BIT7,
    TOUCH_TRIG      = BIT8,
    SAR_TRIG        = BIT9,
    BT_TRIG         = BIT10
} WAKEUP_REASON;	// from rtc_get_wakeup_cause()

// rtc_get_wakeup_cause() returns 0x385 meaning bits: 9,8 7 2,0
//	SAR_TRIG TOUCH_TRIG UART1_TRIG GPIO_TRIG EXT_EVENT0_TRIG

typedef enum {
    NO_MEAN                =  0,
    POWERON_RESET          =  1,    /**<1, Vbat power on reset*/
    SW_RESET               =  3,    /**<3, Software reset digital core*/
    OWDT_RESET             =  4,    /**<4, Legacy watch dog reset digital core*/
    DEEPSLEEP_RESET        =  5,    /**<3, Deep Sleep reset digital core*/
    SDIO_RESET             =  6,    /**<6, Reset by SLC module, reset digital core*/
    TG0WDT_SYS_RESET       =  7,    /**<7, Timer Group0 Watch dog reset digital core*/
    TG1WDT_SYS_RESET       =  8,    /**<8, Timer Group1 Watch dog reset digital core*/
    RTCWDT_SYS_RESET       =  9,    /**<9, RTC Watch dog Reset digital core*/
    INTRUSION_RESET        = 10,    /**<10, Instrusion tested to reset CPU*/
    TGWDT_CPU_RESET        = 11,    /**<11, Time Group reset CPU*/
    SW_CPU_RESET           = 12,    /**<12, Software reset CPU*/
    RTCWDT_CPU_RESET       = 13,    /**<13, RTC Watch dog Reset CPU*/
    EXT_CPU_RESET          = 14,    /**<14, for APP CPU, reseted by PRO CPU*/
    RTCWDT_BROWN_OUT_RESET = 15,    /**<15, Reset when the vdd voltage is not stable*/
    RTCWDT_RTC_RESET       = 16     /**<16, RTC Watch dog reset digital core and rtc module*/
} RESET_REASON;		// from rtc_get_reset_reason()
#endif

static int
format_message (char *message, int mlen)
{
	char *buf = message;
	int blen = mlen;
	int len;
	ulong sleep_us;
	ulong sleep_ticks;
	struct timeval now;
	ulong cycle_us;		// prev cycle  time
	ulong active_us;	// prev active time
	int i;

	sleep_us    = (sleep_start_us > 0)    ? app_start_us    - sleep_start_us    : 0;
	sleep_ticks = (sleep_start_ticks > 0) ? app_start_ticks - sleep_start_ticks : 0;

//Log("sleep_start=%lld app_start=%lld sleep_time=%lld",
//	sleep_start_us, app_start_us, sleep_us);

	len = snprintf (buf, blen,
		"%s %s %d",
		ACTION, MY_NAME, runCount);
	if (len > 0) {
		buf += len;
		blen -= len;
	}

	get_time_since_start (&now);

	struct timeval abs_start;
	get_time_since_wakeup (&abs_start, &app_start);

	len = snprintf (buf, blen,
		" times=D%lu,T%lu,s%u.%03u,S%u,r%.3f,c%.3f,a%.3f,w%.3f,t%u.%06u",
// display in s
		sleep_us, sleep_ticks,
		(uint)app_start.tv_sec, (uint)app_start.tv_usec/1000,
// display in ms
		/*(uint)abs_start.tv_sec,*/ (uint)abs_start.tv_usec/1000,
		(time_temps_us + time_adc_us)/1000., time_temps_us/1000., time_adc_us/1000.,
// display in s
		time_wifi_us / 1000000.,
		(uint)now.tv_sec, (uint)now.tv_usec);
	if (len > 0) {
		buf += len;
		blen -= len;
	}

	if (woke_up) {
		cycle_us = app_start_us - prev_app_start_us;
		active_us = cycle_us - sleep_length_us;
	} else
		cycle_us = active_us = 0;

	len = snprintf (buf, blen,
		" prev=L%.3f,T%lu,c%.6f,a%.6f",
		timeLast / 1000000.,
		(ulong)(timeTotal / 1000000),
		cycle_us  / 1000000.,
		active_us / 1000000.);
	if (len > 0) {
		buf += len;
		blen -= len;
	}

#if SHOW_CLOCKS
    {
	uint64_t RTC   = esp_clk_rtc_time();		// R RTC time (adjusted ticks)
		// RTC = ticks * tCal / 2^19
	uint64_t FRC   = gettimeofday_64();		// F FRC (adjusted)
	uint64_t FRCr  = system_get_time_64();		// f FRC (raw)
	uint32_t tCal = esp_clk_slowclk_cal_get();	// C slow_cal
	uint64_t ticks = rtc_time_get();		// t RTC time (raw ticks, 150mHz)

	len = snprintf (buf, blen,
		" clocks=R%llu,F%llu,f%llu,C%u,t%llu,g%d",
		RTC, FRC, FRCr, tCal, ticks,
		WIFI_GRACE_MS > 0 ? lastGrace : 0);
	if (len > 0) {
		buf += len;
		blen -= len;
	}
    }
#endif

#if SHOW_TIMERS
    {
	esp_err_t ret;
	double tmr_00_sec = 0;
	Dbg (timer_get_counter_time_sec (0, 0, &tmr_00_sec));
	double tmr_01_sec = 0;
	Dbg (timer_get_counter_time_sec (0, 1, &tmr_01_sec)) ;
	double tmr_10_sec = 0;
	Dbg (timer_get_counter_time_sec (1, 0, &tmr_10_sec));
	double tmr_11_sec = 0;
	Dbg (timer_get_counter_time_sec (1, 1, &tmr_11_sec));
	len = snprintf (buf, blen,
		" timers=%.6f,%.6f,%.6f,%.6f",
		tmr_00_sec, tmr_01_sec, tmr_10_sec, tmr_11_sec);
	if (len > 0) {
		buf += len;
		blen -= len;
	}
    }
#endif

	len = snprintf (buf, blen,
		" stats=fs%d,fh%d,fr%d,fR%d",
		WiFiFailSoft, WiFiFailHard, TempFailSoft, TempFailHard);
	if (len > 0) {
		buf += len;
		blen -= len;
	}
#if READ_DS18B20
	len = snprintf (buf, blen,
		",Dc%d,Dr%.4f",
		ds18b20_failures, ds18b20_failure_reason);
	if (len > 0) {
		buf += len;
		blen -= len;
	}
#endif
#if READ_BME280
	len = snprintf (buf, blen,
		",Bc%d",
		bme280_failures);
	if (len > 0) {
		buf += len;
		blen -= len;
	}
#endif

	len = snprintf (buf, blen,
		" v=%.3f,%.3f,%.3f,%.3f",
		bat, vdd, v1, v2);
	if (len > 0) {
		buf += len;
		blen -= len;
	}

	len = snprintf (buf, blen,
		" radio=s%d,c%d",
		-rssi, channel);
	if (len > 0) {
		buf += len;
		blen -= len;
	}

	if ('\0' != weather[0]) {
		len = snprintf (buf, blen,
			"%s",
			weather);
		if (len > 0) {
			buf += len;
			blen -= len;
		}
	}

#ifdef HALL1_PIN
	len = snprintf (buf, blen,
		" hall1=%u,%u",
		ulp_get_count_32(1),	// pulse counter 1
		ulp_get_count_32(11));
	if (len > 0) {
		buf += len;
		blen -= len;
	}
#endif
#ifdef HALL2_PIN
	len = snprintf (buf, blen,
		" hall2=%u,%u",
		ulp_get_count_32(2),    // pulse counter 2
		ulp_get_count_32(12));
	if (len > 0) {
		buf += len;
		blen -= len;
	}
#endif
#ifdef SHOW_HALL_DEBUG
	len = snprintf (buf, blen,
		" loops=%u,%u",
		ulp_loop_count,	// timer
		ulp_shortest_noise);	// longest
	if (len > 0) {
		buf += len;
		blen -= len;
	}
#endif

	len = snprintf (buf, blen,
		" adc=%.3f vdd=%.3f",
		bat, vdd);
	if (len > 0) {
		buf += len;
		blen -= len;
	}

	for (i = 0; i < ntemps; ++i) {
		len = snprintf (buf, blen,
			"%c%.4f",
			(i ? ',' : ' '), temps[i]);
		if (len > 0) {
			buf += len;
			blen -= len;
		}
	}

#ifdef HALL1_PIN
	len = snprintf (buf, blen,
		"%c%u",
		(i ? ',' : ' '), ulp_get_count_32(1));
	if (len > 0) {
		buf += len;
		blen -= len;
	}
	++i;
#endif

#ifdef HALL2_PIN
	len = snprintf (buf, blen,
		"%c%u",
		(i ? ',' : ' '), ulp_get_count_32(2));
	if (len > 0) {
		buf += len;
		blen -= len;
	}
	++i;
#endif

	if (0 == i) {
		len = snprintf (buf, blen,
			"0");
		if (len > 0) {
			buf += len;
			blen -= len;
		}
	}

#if PRINT_MSG
#ifdef USE_WIFI
	if (!do_log)
#endif	// USE_WIFI
		LogF ("%s", message);
#endif	// PRINT_MSG

	if (0) {
		len = snprintf (buf, blen,
			"\n");
		if (len > 0) {
			buf += len;
			blen -= len;
		}
	}

	return mlen - blen;
}

static void
do_grace (void)
{
	if (!sent)
		return;

#if WIFI_GRACE_MS > 0
	toggle(3);
Log ("delay %dms", WIFI_GRACE_MS);
	uint64_t grace_us = gettimeofday_64();
	delay_ms (WIFI_GRACE_MS);	// time to drain wifi queue
	lastGrace = (int)(gettimeofday_64() - grace_us);
#endif
}

static void
finish (void)
{
	struct timeval now;

	++runCount;

	if (retry_count > 1)
		++WiFiFailHard;
	else if (retry_count > 0)
		++WiFiFailSoft;

// there is no way to check when the wifi transmit buffer is empty
// so we just delay for a grace period.
	if (sent) {
		do_grace ();

Log ("Stopping WiFi");
		stop_wifi();
//		delay_ms (30);	// DEBUG
	}

Log ("esp_deep_sleep %ds", SLEEP_S);
	flush_uart();

	esp_sleep_pd_config(ESP_PD_DOMAIN_RTC_PERIPH, ESP_PD_OPTION_AUTO);
	esp_sleep_pd_config(ESP_PD_DOMAIN_RTC_SLOW_MEM, ESP_PD_OPTION_AUTO);
	esp_sleep_pd_config(ESP_PD_DOMAIN_RTC_FAST_MEM, ESP_PD_OPTION_AUTO);
	esp_sleep_pd_config(ESP_PD_DOMAIN_XTAL, ESP_PD_OPTION_AUTO);
//	rtc_gpio_isolate(GPIO_NUM_0);
//	rtc_gpio_isolate(GPIO_NUM_12);
//	rtc_gpio_isolate(GPIO_NUM_15);

	toggle(4);
	sleep_start_us = gettimeofday_64();
	sleep_start_ticks = rtc_time_get ();
	prev_app_start_us = app_start_us;
	timeLast = sleep_start_us - app_start_us;

// Estimate active time now and total
	gettimeofday (&now, NULL);
	timeLast = (now.tv_sec  - wakeup.tv_sec) * 1000000UL
		  + now.tv_usec - wakeup.tv_usec;
	timeTotal += timeLast;

// Estimate wakeup time
	sleep_length_us = SLEEP_S*1000000 - timeLast;
	if (sleep_length_us <= 0)
		sleep_length_us = 1;

// wakeup is the wall clock expected when wakeup starts
	wakeup.tv_sec  = now.tv_sec;
	wakeup.tv_usec = now.tv_usec + sleep_length_us;
	wakeup.tv_sec += wakeup.tv_usec / 1000000UL;
	wakeup.tv_usec = wakeup.tv_usec % 1000000UL;

	esp_deep_sleep(sleep_length_us);
	vTaskDelete(NULL);
}

static esp_err_t
app (void)
{
	char message[500];
	int mlen;

#ifdef USE_WIFI
	DbgR (wait_for_wifi());
#endif	// USE_WIFI

// need to do this late to have wifi timing
Log ("format_message");
	mlen = format_message (message, sizeof(message));

#ifdef USE_WIFI
Log ("wifi_send_message");
	wifi_send_message (message, mlen);
Log ("sent message");
	sent = 1;
#else
	(void)mlen;	// avoid unused warning
#endif	// USE_WIFI

	return ESP_OK;
}

static void
main_task(void *param)
{
	esp_err_t ret = ESP_OK;

// reading voltages is more stable before wifi starts

#ifdef READ_VOLTAGES_EARLY
Log("read_voltages");
	(void)read_voltages();
#endif

#ifdef USE_WIFI
Log ("xEventGroupCreate");
	event_group = xEventGroupCreate();

	Dbg (wifi_setup ());
#endif	// USE_WIFI

#ifndef READ_VOLTAGES_EARLY
Log("read_voltages");
	(void)read_voltages();
#endif

	(void)read_temps();

	if (ESP_OK == ret)
		Dbg (app());

	power_off ();

	finish ();

	while (1) vTaskDelay(5000/portTICK_PERIOD_MS);	// in 5s we will sleep anyway
}

// See components/esp32/include/esp_system.h for
static void
show_info (void)
{
	uint8_t mac[6];
	esp_chip_info_t chip_info;

//	Log ("app_main start portTICK_PERIOD_MS=%d sizeof(int)=%d sizeof(long)=%d",
//		portTICK_PERIOD_MS, sizeof(int), sizeof(long));

	Log ("app built at %s %s", __DATE__, __TIME__);

	esp_chip_info(&chip_info);
	Log ("Chip model %d, revision %d, #cores %d",
		chip_info.model, chip_info.revision, chip_info.cores);

	esp_efuse_mac_get_default(mac);
	Log ("MAC %02x:%02x:%02x:%02x:%02x:%02x", mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);

	Log ("IDF version '%s'", esp_get_idf_version());
}

void
app_main ()
{
	// app_start is time when this app started (later than wakeup time)
	app_start_us = gettimeofday_64();
	app_start_ticks = rtc_time_get ();
	app_start.tv_sec  = app_start_us / 1000000;
	app_start.tv_usec = app_start_us % 1000000;

	WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0);	//disable brownout detector

	power_on ();		// do this early to allow stable power

#if TOGGLE_PIN >= 0
	gpio_pad_select_gpio(TOGGLE_PIN);
	gpio_set_direction(TOGGLE_PIN, GPIO_MODE_INPUT);
	gpio_pullup_en(TOGGLE_PIN);
#endif

#if DBG_PIN >= 0
	gpio_pad_select_gpio(DBG_PIN);
	gpio_set_direction(DBG_PIN, GPIO_MODE_INPUT);
	gpio_pullup_en(DBG_PIN);
#endif

#if TOGGLE_PIN >= 0
	do_toggle = !gpio_get_level(TOGGLE_PIN);
#endif
	if (do_toggle)
		toggle_setup();

#if DBG_PIN >= 0
	do_log = !gpio_get_level(DBG_PIN);
#endif
// turn off internal messages below ERROR level
	if (!do_log) esp_log_level_set("*", ESP_LOG_ERROR);

	wakeup_cause = rtc_get_wakeup_cause();
	reset_reason = rtc_get_reset_reason(0);
	woke_up = reset_reason == DEEPSLEEP_RESET;

	if (do_log && !woke_up)	// cold start
		delay_ms (100);	// give 'screen' time to start

	show_info ();

	if (woke_up) {		// deepsleep wakeup
#ifdef SHOW_HALL_DEBUG
		ulp_loop_count     = ulp_get_count_32(0);
		ulp_shortest_noise = ulp_get_count_16(13);
#endif
	} else {		// cold start
#if SHOW_PULSES
#ifdef HALL1_PIN
		p1_pin = HALL1_PIN;
#endif
#ifdef HALL2_PIN
		p2_pin = HALL2_PIN;
#endif
		ulp_init_program();
#endif
	}

// do we need a RTC_DATA_ATTR magic?

	xTaskCreatePinnedToCore(main_task, "udp", APP_TASK_STACK, NULL,
		APP_TASK_PRIORITY, NULL, APP_CPU_AFFINITY);
}

