/* UDP reporting Example

   This example code is in the Public Domain (or CC0 licensed, at your option.)

   Unless required by applicable law or agreed to in writing, this
   software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
   CONDITIONS OF ANY KIND, either express or implied.
*/

#include "udp.h"
#include "wifi.h"

#include <esp_log.h>
#include <rom/rtc.h>
#include <rom/uart.h>		// uart_tx_wait_idle()
#include <driver/timer.h>	// timer_get_counter_time_sec()
#include <soc/efuse_reg.h>	// needed by getChip*()

#include <soc/rtc.h>
#include <esp_clk.h>

#ifndef MY_NAME
#define MY_NAME			"test"
#endif

#define WAKEUP_MS		160	// ms from power up to app_main
#define SLEEP_S			60	// seconds
#define WIFI_GRACE_MS		50	// time to wait before deep sleep to drain wifi tx
#define WIFI_TIMEOUT_MS		5000	// time to wait for WiFi connection
#define WIFI_DISCONNECT_MS	100	// time to wait for WiFi disconnection

#define DISCONNECT		0	// 1= disconnect before deep sleep
#define PRINT_MSG		0	// 1= print sent message if logging is off

#define APP_CPU_AFFINITY	1	// 0, 1 or tskNO_AFFINITY

// tskIDLE_PRIORITY + n
// configMAX_PRIORITIES - n
#define APP_TASK_PRIORITY	(tskIDLE_PRIORITY+5)
#define APP_TASK_STACK		(8*1024)

#define I2C_SCL			22	// i2c
#define I2C_SDA			21	// i2c
#define OUT_PIN			19	// OUT toggled to mark program steps
#define OW_PIN			18	// IO  ow
#define ERROR_PIN		17	// OUT indicate a failure (debug). -ve to disable
#define TOGGLE_PIN		16	// IN  pull low to disable toggle()
#define DBG_PIN			15	// IN  pull low to silence Log()

			// adc pins are 32-39
#define VDD_PIN			32	// undef to disable
#define VDD_DIVIDER		2	// 1m.1m
#define VDD_ATTEN		6	// 6db

#define BAT_PIN			33	// undef to disable
#define BAT_DIVIDER		3	// 1m.2m
#define BAT_ATTEN		6	// 6db

#define V1_PIN			34	// undef to disable
#define V1_DIVIDER		1	// resistor network
#define V1_ATTEN		6	// 6db

#define READ_TSENS		1	// read esp32 temperature sensor

#if   62 == MY_HOST	// esp-32a
#define READ_BME280		1	// enable if you have one connected
#define READ_DS18B20		1	// enable if you have one connected
#define BAT_VOLTAGE		5.0
#undef  V1_PIN
#define ADC_VREF		1130	// measured
#undef SLEEP_S
#define SLEEP_S			(10*60)	// 10m in seconds
#define ACTION			"store"

#elif 64 == MY_HOST	// esp-32b
#define READ_BME280		0	// enable if you have one connected
#define READ_DS18B20		1	// enable if you have one connected
#define BAT_VOLTAGE		3.3
#undef  V1_PIN
#define ADC_VREF		1094	// measured when Vdd=3.313v
#undef VDD_DIVIDER
#define VDD_DIVIDER		(2*1.016)
#undef SLEEP_S
#define SLEEP_S			(1*60)	// 1m in seconds
#define ACTION			"store"

#elif 65 == MY_HOST	// esp-32c
#define READ_BME280		0	// enable if you have one connected
#define READ_DS18B20		1	// enable if you have one connected
#define BAT_VOLTAGE		3.3
#undef  V1_PIN
#define ADC_VREF		1113	// measured when Vdd=3.272v
#undef SLEEP_S
#define SLEEP_S			(5*60)	// 5m in seconds
#define ACTION			"store"

#else
#error unknown host MY_HOST
#endif

#define READ_ADC		(defined(VDD_PIN) || defined(BAT_PIN) || defined(V1_PIN))

#if READ_ADC
#include "adc.h"
#endif

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
  #define ROM_ID		NULL	// when only one ow device connected, fastest
//#define ROM_ID		(uint8_t *)"\x28\xdc\x01\x78\x06\x00\x00\x0f"	// esp-32a
//#define ROM_ID		(uint8_t *)"\x28\xc5\x3e\x76\x06\x00\x00\x3c"	// esp-32b
//#define ROM_ID		(uint8_t *)"\x28\xa9\x7f\x78\x06\x00\x00\xb3"	// esp-32c
RTC_DATA_ATTR static int ds18b20_failures = 0;
#endif

#if READ_TSENS
#include "tsens.h"
#endif

int do_log = 1;
uint64_t time_wifi_us = 0;
int rssi = 0;
int channel = 0;
int sent = 0;
int retry_count = 0;
bool woke_up = 0;


RTC_DATA_ATTR static int runCount = 0;
RTC_DATA_ATTR static uint64_t sleep_start_us = 0;
RTC_DATA_ATTR static uint64_t sleep_start_ticks = 0;
RTC_DATA_ATTR static uint64_t sleep_length_us = 0;
RTC_DATA_ATTR static uint64_t prev_app_start_us = 0;
RTC_DATA_ATTR static int failSoft = 0;
RTC_DATA_ATTR static int failHard = 0;
RTC_DATA_ATTR static int failRead = 0;
RTC_DATA_ATTR static int failReadHard = 0;
RTC_DATA_ATTR static int lastGrace = 0;
RTC_DATA_ATTR static uint64_t timeLast = 0;
RTC_DATA_ATTR static uint64_t timeTotal = 0;

static int do_toggle = 0;
static struct timeval app_start;
static uint64_t app_start_us = 0;
static uint64_t app_start_ticks = 0;
static int wakeup_cause;
static int reset_reason;

#if 001
// this is my simplified version of _gettimeofday_r(), added to time.c
uint64_t gettimeofday_us(void);		// FRC
#else
// or you can add it here:
uint64_t gettimeofday_us(void)
{
	struct timeval tv;

	gettimeofday (&tv, NULL);
	return tv.tv_sec*1000000 + tv.tv_usec;
}
#endif

void flush_uart (void)
{
	fflush(stdout);
	uart_tx_wait_idle(CONFIG_CONSOLE_UART_NUM);
}

static void toggle_setup (void)
{
#if OUT_PIN >= 0
	gpio_pad_select_gpio(OUT_PIN);
	gpio_set_direction(OUT_PIN, GPIO_MODE_OUTPUT);
	gpio_set_level(OUT_PIN, 1);	// start HIGH
#endif
}

#if USE_DELAY_BUSY
void delay_us_busy (int us)
{
	uint64_t end = gettimeofday_us() + us;
	while (gettimeofday_us() < end)
		{}
}
#endif

// pin is LOW  during sleep
// pin is HIGH at start
// toggle is 100us: 50us LOW, 50us HIGH (not on final time)
static void toggle_out (int ntimes, int us)
{
	if (do_toggle) while (ntimes-- > 0) {
		gpio_set_level(OUT_PIN, 0);
		delay_us (us);
		gpio_set_level(OUT_PIN, 1);
		if (ntimes)
			delay_us (us);
	}
}

void toggle (int ntimes) {
	toggle_out (ntimes, 50);
}

void toggle_short (int ntimes) {
	toggle_out (ntimes, 2);
}

#if ERROR_PIN >= 0
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

void get_time_tv (struct timeval *now)
{
	gettimeofday (now, NULL);
	if (now->tv_usec < app_start.tv_usec) {
		now->tv_usec += 1000000;
		--now->tv_sec;
	}

	now->tv_sec  -= app_start.tv_sec;
	now->tv_usec -= app_start.tv_usec;
}

#if 000	// not used
static uint64_t get_time_us (void) {
	return gettimeofday_us() - app_start_us;
}
#endif

#if READ_DS18B20
static esp_err_t ds18b20_temp (float *temp)
{
	esp_err_t ret;
	esp_err_t rval;		// return first failure
	uint8_t id[8];

	*temp = 0.0;
	rval = ESP_OK;

	DbgR (ds18b20_init (OW_PIN, ROM_ID));

	if (!woke_up) {
		DbgR (ds18b20_read_id (id));
		Log("ds18b20 ROM id: %02x %02x %02x %02x %02x %02x %02x %02x",
			id[0], id[1], id[2], id[3], id[4], id[5], id[6], id[7]);

		DbgR (ds18b20_convert (1));
	}
	Dbg (ds18b20_read_temp (temp));
	if (ESP_OK == rval) rval = ret;

	Dbg (ds18b20_convert (0));
	if (ESP_OK == rval) rval = ret;

	Dbg (ds18b20_depower ());
	if (ESP_OK == rval) rval = ret;

	return rval;
}
#endif // READ_DS18B20

#define MAX_TEMPS		3
static int ntemps = 0;
static float temps[MAX_TEMPS];
static float bat, vdd, v1;
static char weather[40] = "";
static float ds18b20_failure_reason = 0;
static uint64_t time_readings_us = 0;

// save first failure in 'rval'
//
#define DbgRval(f) \
do { \
	Dbg (f); \
	if (ESP_OK == rval) rval = ret; \
} while (0)

static esp_err_t read_temps (void)
{
	esp_err_t ret;
	esp_err_t rval;		// return first failure
	float temp;

	rval = ESP_OK;

#if READ_DS18B20
	if (ntemps < MAX_TEMPS) {
		DbgRval (ds18b20_temp (&temp));
		if (ret != ESP_OK || temp >= BAD_TEMP) {
			toggle_error();		// tell DSO
			++ds18b20_failures;
			ds18b20_failure_reason = temp;
			DbgRval (ds18b20_temp (&temp));	// one retry
			if (ret != ESP_OK || temp >= BAD_TEMP) {
				toggle_error();		// tell DSO
				++failReadHard;
				temp = BAD_TEMP;
			} else
				++failRead;
		}
		temps[ntemps++] = temp;
	}
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
			++failRead;
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

	return rval;
}

static esp_err_t do_readings (void)
{
	esp_err_t ret;
	esp_err_t rval;		// return first failure

	flush_uart ();		// avoid uart interruptions

	time_readings_us = gettimeofday_us();
	ntemps = 0;
	rval = ESP_OK;

	DbgRval (read_temps ());


	if (0 == ntemps)
		if (ntemps < MAX_TEMPS) temps[ntemps++] = 0;

#if READ_ADC
	DbgRval (adc_init (12, ADC_VREF));
#endif

#ifdef VDD_PIN
	DbgRval (adc_read (&vdd, VDD_PIN, VDD_ATTEN, VDD_DIVIDER));
#else
	vdd = 3.3;
#endif

#ifdef BAT_PIN
	DbgRval (adc_read (&bat, BAT_PIN, BAT_ATTEN, BAT_DIVIDER));
#else
	bat = BAT_VOLTAGE;
#endif

#ifdef V1_PIN
	DbgRval (adc_read (&v1, V1_PIN, V1_ATTEN, V1_DIVIDER));
#else
	v1 = 0;
#endif

	time_readings_us = gettimeofday_us() - time_readings_us;

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

static int format_message (char *message, int mlen)
{
	char *buf = message;
	int blen = mlen;
	int len;
	uint64_t sleep_us;
	uint64_t sleep_ticks;
	struct timeval now;
	uint64_t cycle_us;		// prev cycle  time
	uint64_t active_us;		// prev active time
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

	get_time_tv (&now);

	len = snprintf (buf, blen,
		" times=D%lld,T%lld,s%u.%06u,r%.3f,w%.3f,t%u.%06u",
		sleep_us, sleep_ticks,
		(uint)app_start.tv_sec, (uint)app_start.tv_usec,
		time_readings_us / 1000000.,
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
		" prev=L%.3f,T%d,c%.6f,a%.6f",
		timeLast / 1000000.,
		(uint32_t)(timeTotal / 1000000),
		cycle_us  / 1000000.,
		active_us / 1000000.);
	if (len > 0) {
		buf += len;
		blen -= len;
	}

    {
	uint64_t get_time_since_boot_64(void);		// my exported 64-bit version

	uint64_t RTC   = esp_clk_rtc_time();		// R RTC time (adjusted ticks)
		// RTC = ticks * tCal / 2^19
	uint64_t FRC   = gettimeofday_us();		// F FRC (adjusted)
	uint64_t FRCr  = get_time_since_boot_64();	// f FRC (raw)
	uint32_t tCal = esp_clk_slowclk_cal_get();	// C slow_cal
	uint64_t ticks = rtc_time_get();		// t RTC time (raw ticks, 150mHz)

	len = snprintf (buf, blen,
		" clocks=R%llu,F%llu,f%llu,C%u,t%llu,g%d",
		RTC, FRC, FRCr, tCal, ticks, lastGrace);
	if (len > 0) {
		buf += len;
		blen -= len;
	}
    }

#if 000
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
		failSoft, failHard, failRead, failReadHard);
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
		",c%03x,r%d",
		wakeup_cause, reset_reason);
	if (len > 0) {
		buf += len;
		blen -= len;
	}

	len = snprintf (buf, blen,
		" v=%.3f,%.3f,%.3f",
		bat, vdd, v1);
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

#if PRINT_MSG
	if (!do_log)
		LogF ("%s", message);
#endif

	return mlen - blen;
}

static void do_grace (void)
{
	if (!sent)
		return;

#if defined(WIFI_GRACE_MS) && WIFI_GRACE_MS > 0
	toggle(3);
Log ("delay %dms", WIFI_GRACE_MS);
	uint64_t grace_us = gettimeofday_us();
	delay_ms (WIFI_GRACE_MS + do_log*5);	// time to drain wifi queue
	lastGrace = (int)(gettimeofday_us() - grace_us);
#endif
}

static void finish (void)
{
	++runCount;

	if (retry_count > 1)
		++failHard;
	else if (retry_count > 0)
		++failSoft;

	if (sent)
		do_grace ();

#if DISCONNECT
	DbgR (esp_disconnect());

Log ("xEventGroupWaitBits(NO_WIFI)");
	xEventGroupWaitBits(event_group, NO_WIFI,
		false, false, WIFI_DISCONNECT_MS / portTICK_PERIOD_MS);
#endif

Log ("esp_deep_sleep %ds", SLEEP_S);
	flush_uart();
	if (do_log)
		delay_ms(5);	// or else we do not see final messages

	toggle(4);
	sleep_start_us = gettimeofday_us();
	sleep_start_ticks = rtc_time_get ();
	prev_app_start_us = app_start_us;
	timeLast = sleep_start_us - app_start_us;
	timeTotal += timeLast;
#if 000	// fixed cycle length
	sleep_length_us = SLEEP_S*1000000 - sleep_start_us;
	if (sleep_length_us <= 0)
		sleep_length_us = 1;
#else	// fixed sleep length
	sleep_length_us = SLEEP_S*1000000;
#endif
	esp_deep_sleep(sleep_length_us);
	vTaskDelete(NULL);
}

static esp_err_t app (void)
{
	EventBits_t bits;
	char message[500];
	int mlen;

Log("do_readings");
	(void)do_readings();

Log("xEventGroupWaitBits(HAVE_WIFI|NO_WIFI)");
	xEventGroupWaitBits(event_group, HAVE_WIFI|NO_WIFI,
		false, false, WIFI_TIMEOUT_MS / portTICK_PERIOD_MS);
	bits = xEventGroupGetBits (event_group);
	if (0 == bits)
		LogR (ESP_FAIL, "WiFi timed out, aborting");
	if (!(HAVE_WIFI & bits))
		LogR (ESP_FAIL, "no WiFi, aborting");
Log ("have WiFi");

// need to do this late to have wifi timing
Log ("format_message");
	mlen = format_message (message, sizeof(message));

Log ("wifi_send_message");
	wifi_send_message (message, mlen);
Log ("sent message");
	sent = 1;

	return ESP_OK;
}

static void main_task(void *param)
{
	esp_err_t ret;

Log ("xEventGroupCreate");
	event_group = xEventGroupCreate();

	Dbg (wifi_setup ());
	if (ESP_OK == ret)
		Dbg (app());

	finish ();

	while (1) vTaskDelay(5000/portTICK_PERIOD_MS);	// in 5s we will sleep anyway
}

void app_main ()
{
	app_start_us = gettimeofday_us();
	app_start_ticks = rtc_time_get ();
	app_start.tv_sec  = app_start_us / 1000000;
	app_start.tv_usec = app_start_us % 1000000;

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

// leave a gap between setting the pins up and reading them.

#if TOGGLE_PIN >= 0
	do_toggle = gpio_get_level(TOGGLE_PIN);
#endif
	if (do_toggle)
		toggle_setup();

#if DBG_PIN >= 0
	do_log = gpio_get_level(DBG_PIN);
#endif
// turn off internal messages below ERROR level
	if (!do_log) esp_log_level_set("*", ESP_LOG_ERROR);

	wakeup_cause = rtc_get_wakeup_cause();
	reset_reason = rtc_get_reset_reason(0);
	woke_up = reset_reason == DEEPSLEEP_RESET;

	if (do_log && !woke_up)	// cold start
		delay_ms (100);	// give 'screen' time to start

	Log ("app built at %s %s", __DATE__, __TIME__);

//Log ("app_main start portTICK_PERIOD_MS=%d sizeof(int)=%d sizeof(long)=%d",
//	portTICK_PERIOD_MS, sizeof(int), sizeof(long));

// See components/esp32/include/esp_system.h for
{
	uint8_t mac[6];
	esp_chip_info_t chip_info;

	esp_chip_info(&chip_info);
	Log ("Chip model %d, revision %d, #cores %d",
		chip_info.model, chip_info.revision, chip_info.cores);

	esp_efuse_mac_get_default(mac);
	Log ("MAC %02x:%02x:%02x:%02x:%02x:%02x", mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);

	Log ("IDF verion '%s'", esp_get_idf_version());
}

// do we need a RTC_DATA_ATTR magic?

	xTaskCreatePinnedToCore(main_task, "udp", APP_TASK_STACK, NULL,
		APP_TASK_PRIORITY, NULL, APP_CPU_AFFINITY);
}

