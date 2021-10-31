/* UDP reporting Example

   This example code is in the Public Domain (or CC0 licensed, at your option.)

   Unless required by applicable law or agreed to in writing, this
   software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
   CONDITIONS OF ANY KIND, either express or implied.
*/

#include "udp.h"
#include "wifi.h"

#include <esp_log.h>
#include <esp32/rom/rtc.h>
#include <esp32/rom/uart.h>	// uart_tx_wait_idle()
#include <driver/timer.h>	// timer_get_counter_time_sec()
#include <soc/efuse_reg.h>	// needed by getChip*()

#include <soc/rtc.h>
#include <esp32/clk.h>
#include <esp_sleep.h>

#ifndef MY_NAME
#define MY_NAME			"esp-32f"
#endif

#define WAKEUP_MS		160	// ms from power up to app_main
#define SLEEP_S			10	// seconds, default
#define WIFI_GRACE_MS		50	// time to wait before deep sleep to drain wifi tx
#define WIFI_TIMEOUT_MS		5000	// time to wait for WiFi connection
#define WIFI_DISCONNECT_MS	100	// time to wait for WiFi disconnection

#define DISCONNECT		0	// 1= disconnect before deep sleep
#define PRINT_MSG		1	// 1= print sent message if logging is off
#define USING_EYALS_SERVER	1	// only when Eyal tests at home

#define APP_CPU_AFFINITY	1	// 0, 1 or tskNO_AFFINITY

// tskIDLE_PRIORITY + n
// configMAX_PRIORITIES - n
#define APP_TASK_PRIORITY	(tskIDLE_PRIORITY+5)
#define APP_TASK_STACK		(8*1024)

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
RTC_DATA_ATTR static int lastGrace = 0;
RTC_DATA_ATTR static uint64_t timeLast = 0;
RTC_DATA_ATTR static uint64_t timeTotal = 0;

static struct timeval app_start;
static uint64_t app_start_us = 0;
static uint64_t app_start_ticks = 0;
static int wakeup_cause;
static int reset_reason;

// if you did not add gettimeofday_64 to components/newlib/time.c then enable this:
#if 000
uint64_t gettimeofday_64(void)
{
	struct timeval tv;

	gettimeofday (&tv, NULL);
	return tv.tv_sec*1000000ULL + tv.tv_usec;
}
#endif

// if you did not add system_get_time_64 to components/newlib/time.c then enable this:
#if 000
uint64_t system_get_time_64(void) {
	return system_get_time();
}
#endif

void flush_uart (void)
{
	fflush(stdout);
	uart_tx_wait_idle(CONFIG_ESP_CONSOLE_UART_NUM);
}


#if USE_DELAY_BUSY
void delay_us_busy (int us)
{
	uint64_t end = gettimeofday_64() + us;
	while (gettimeofday_64() < end)
		{}
}
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

// save first failure in 'rval'
//
#define DbgRval(f) \
do { \
	Dbg (f); \
	if (ESP_OK == rval) rval = ret; \
} while (0)

static int
format_message (char *message, int mlen)
{
	mlen = snprintf (message, mlen,
#if USING_EYALS_SERVER
		"store esp-32f "
#endif
		"%3d: Hello World! WiFi took %lums",
		runCount, (ulong)time_wifi_us/1000);

#if PRINT_MSG
	if (!do_log)
		LogF ("%s", message);
#endif

	return mlen;
}

static void
do_grace (void)
{
	if (!sent)
		return;

#if defined(WIFI_GRACE_MS) && WIFI_GRACE_MS > 0
Log ("delay %dms", WIFI_GRACE_MS);
	uint64_t grace_us = gettimeofday_64();
	delay_ms (WIFI_GRACE_MS + do_log*5);	// time to drain wifi queue
	lastGrace = (int)(gettimeofday_64() - grace_us);
#endif
}

static void
finish (void)
{
	++runCount;

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

	sleep_start_us = gettimeofday_64();
	sleep_start_ticks = rtc_time_get ();
	prev_app_start_us = app_start_us;
	timeLast = sleep_start_us - app_start_us;
	timeTotal += timeLast;
#if 001	// fixed cycle length
//Log("sleep_start_us=%lu", (unsigned long)sleep_start_us);
//Log("sleep_start_ticks=%lu", (unsigned long)sleep_start_ticks);
//Log("app_start_us=%lu", (unsigned long)app_start_us);
//Log("timeLast=%lu", (unsigned long)timeLast);
	sleep_length_us = SLEEP_S*1000000 - timeLast;
	if (sleep_length_us <= 0)
		sleep_length_us = 1;
#else	// fixed sleep length
	sleep_length_us = SLEEP_S*1000000;
#endif
	esp_deep_sleep(sleep_length_us);
	vTaskDelete(NULL);
}

static esp_err_t
app (void)
{
	EventBits_t bits;
	char message[500];
	int mlen;

Log("xEventGroupWaitBits(HAVE_WIFI|NO_WIFI)");
	xEventGroupWaitBits(event_group, HAVE_WIFI|NO_WIFI,
		false, false, WIFI_TIMEOUT_MS / portTICK_PERIOD_MS);
	bits = xEventGroupGetBits (event_group);
	if (0 == bits)
		LogR (ESP_FAIL, "WiFi timed out, aborting");
	if (!(HAVE_WIFI & bits))
		LogR (ESP_FAIL, "no WiFi, aborting");
//Log ("have WiFi");

// need to do this late to have wifi timing
Log ("format_message");
	mlen = format_message (message, sizeof(message));

Log ("wifi_send_message");
	wifi_send_message (message, mlen);
Log ("sent message");
	sent = 1;

	return ESP_OK;
}

static void
main_task(void *param)
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

// See components/esp32/include/esp_system.h for
void
show_info (void)
{
	esp_chip_info_t chip_info;
//	uint8_t mac[6];

//	Log ("app_main start portTICK_PERIOD_MS=%d sizeof(int)=%d sizeof(long)=%d",
//		portTICK_PERIOD_MS, sizeof(int), sizeof(long));

	Log ("app built at %s %s", __DATE__, __TIME__);

	esp_chip_info(&chip_info);
	Log ("Chip model %d, revision %d, #cores %d",
		chip_info.model, chip_info.revision, chip_info.cores);

//	esp_efuse_mac_get_default(mac);
//	Log ("MAC %02x:%02x:%02x:%02x:%02x:%02x", mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);

	Log ("IDF version '%s'", esp_get_idf_version());
}

void
app_main ()
{
	app_start_us = gettimeofday_64();
	app_start_ticks = rtc_time_get ();
	app_start.tv_sec  = app_start_us / 1000000;
	app_start.tv_usec = app_start_us % 1000000;

	WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0);	//disable brownout detector

// turn off internal messages below ERROR level
//	if (!do_log) esp_log_level_set("*", ESP_LOG_ERROR);
	esp_log_level_set("*", ESP_LOG_INFO);

	wakeup_cause = rtc_get_wakeup_cause();
	reset_reason = rtc_get_reset_reason(0);
	woke_up = reset_reason == DEEPSLEEP_RESET;

	if (do_log && !woke_up)	// cold start
		delay_ms (100);	// give 'screen' time to start

	show_info ();

// do we need a RTC_DATA_ATTR magic?

	xTaskCreatePinnedToCore(main_task, "udp", APP_TASK_STACK, NULL,
		APP_TASK_PRIORITY, NULL, APP_CPU_AFFINITY);
}

