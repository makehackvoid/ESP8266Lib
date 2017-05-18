/* UDP reporting Example

   This example code is in the Public Domain (or CC0 licensed, at your option.)

   Unless required by applicable law or agreed to in writing, this
   software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
   CONDITIONS OF ANY KIND, either express or implied.
*/
#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_system.h"
#include "esp_spi_flash.h"
#include "esp_err.h"
#include "esp_phy_init.h"

#include <string.h>
#include <esp_wifi.h>
#include <esp_event_loop.h>
#include <sys/socket.h>
#include <rom/rtc.h>

#define AP_SSID		"SSID"
#define AP_PASS		"PASS"
#define SVR_IP		"192.168.2.7"
#define SVR_PORT	21883

#define MY_IP		"192.168.2.62"
#define MY_NM		"255.255.255.0"
#define MY_GW		SVR_IP

#define SLEEP_S		5
#define GRACE_MS	30	// 5ms is too short

#define USE_DHCPC	0	// 0=no, use static IP
#define DISCONNECT	0	// 0=no disconnect before deep sleep
#define LOG_FLUSH	0	// 0=no flush after each Log message

#define DBG_PIN		15
#define OUT_PIN		17

RTC_DATA_ATTR static int n = 0;
RTC_DATA_ATTR static struct timeval sleep_start = {0, 0};

//static uint64_t time_since_boot;

static struct timeval app_start;
static int wakeup_cause, reset_reason;
static int rssi = 0;
static int do_log = 0;
static int done = 0;

static void delay (int ms)
{
	vTaskDelay(ms / portTICK_PERIOD_MS);
}

// pin is LOW  during sleep
// pin is HIGH at start
static void toggle() {
	gpio_set_level(OUT_PIN, 0);
	delay (1);
	gpio_set_level(OUT_PIN, 1);
}

#define Dbg	printf("%d\n", __LINE__);

#define Log(fmt,...) \
if (do_log) do { \
	struct timeval now; \
\
	get_time (&now); \
	printf ("%3lu.%06lu " fmt "\n", now.tv_sec, now.tv_usec, ##__VA_ARGS__); \
	if (LOG_FLUSH) fflush(stdout); \
} while (0)

static void get_time (struct timeval *now)
{
	gettimeofday (now, NULL);
	if (now->tv_usec < app_start.tv_usec) {
		now->tv_usec += 1000000;
		--now->tv_sec;
	}

	now->tv_sec  -= app_start.tv_sec;
	now->tv_usec -= app_start.tv_usec;
}

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

static void format_msg (char *msg, int mlen)
{
	struct timeval now;
	int s, us;

Log("sleep_start=%ld.%06ld app_start=%ld.%06ld",
	sleep_start.tv_sec, sleep_start.tv_usec,
	  app_start.tv_sec,   app_start.tv_usec);

	if (sleep_start.tv_sec > 0) {
		s =  (int)(app_start.tv_sec  - sleep_start.tv_sec);
		us = (int)(app_start.tv_usec - sleep_start.tv_usec);
		if (us < 0) {
			us += 1000000;
			--s;
		}
	} else
		s = us = 0;

	get_time (&now);

// times=s0.094,u0.045,r0.047,w0.070,F0.000,S0.010,d0.100,t0.301
	snprintf (msg, mlen,
		"show esp-32a %d times=w%d.%06d,s%u.%06u,t%u.%06u stats=fs%d,fh%d,fr%d,c%03x,r%d radio=s%d",
		n,
		s, us,
		(uint)app_start.tv_sec, (uint)app_start.tv_usec,
		(uint)now.tv_sec, (uint)now.tv_usec,
		0, 0, 0,	// failures not counted yet
		wakeup_cause, reset_reason,
		-rssi);
	++n;
}

static void send_msg (void)
{
	int mysocket;
	struct sockaddr_in remote_addr;
	char msg[200];

	mysocket = socket(AF_INET, SOCK_DGRAM, 0);
	remote_addr.sin_family = AF_INET;
	remote_addr.sin_port = htons(SVR_PORT);
	remote_addr.sin_addr.s_addr = inet_addr(SVR_IP);

	format_msg (msg, sizeof(msg));

Log ("Sending '%s'", msg);
	sendto(mysocket, msg, strlen(msg), 0,
		(struct sockaddr *)&remote_addr, sizeof(remote_addr));
}

static void esp_vendor_ie_cb (
	void *ctx,
	wifi_vendor_ie_type_t type,
	const uint8_t sa[6],
	const uint8_t *vnd_ie,
	int _rssi)
{
Log ("Received rssi=%d", _rssi);
	rssi = _rssi;
}

static void finish (void)
{
#if !DISCONNECT && defined(GRACE_MS) && GRACE_MS > 0
Log ("delay %dms", GRACE_MS);
	delay(GRACE_MS);	// time to send UDP message
#endif

Log ("esp_deep_sleep %ds", SLEEP_S);
#if !LOG_FLUSH
	fflush(stdout);
#endif

	gettimeofday (&sleep_start, NULL);
	toggle();
	esp_deep_sleep(SLEEP_S*1000000);
}

static esp_err_t event_handler (void *ctx, system_event_t *event)
{
	switch(event->event_id) {
	case SYSTEM_EVENT_STA_START:
Log ("SYSTEM_EVENT_STA_START");

#if !USE_DHCPC
Log ("tcpip_adapter_dhcpc_stop");
		tcpip_adapter_dhcpc_stop(TCPIP_ADAPTER_IF_STA);

Log ("tcpip_adapter_set_ip_info");
		tcpip_adapter_ip_info_t ip_info_new;
		memset (&ip_info_new, 0, sizeof(ip_info_new));
		ip4addr_aton(MY_IP, &ip_info_new.ip);
		ip4addr_aton(MY_NM, &ip_info_new.netmask);
		ip4addr_aton(MY_GW, &ip_info_new.gw);
		tcpip_adapter_set_ip_info(TCPIP_ADAPTER_IF_STA, &ip_info_new);
#endif	/* if !USE_DHCPC */

Log ("esp_wifi_set_vendor_ie_cb rc=%d",
		esp_wifi_set_vendor_ie_cb(esp_vendor_ie_cb, NULL));

Log ("esp_wifi_connect");
		toggle();
		esp_wifi_connect();
		break;
	case SYSTEM_EVENT_STA_CONNECTED:
		toggle();
Log ("SYSTEM_EVENT_STA_CONNECTED");
		break;
	case SYSTEM_EVENT_STA_GOT_IP:
{
char ip[16], nm[16], gw[16];
Log ("SYSTEM_EVENT_STA_GOT_IP ip=%s nm=%s gw=%s",
	ip4addr_ntoa_r(&event->event_info.got_ip.ip_info.ip, ip, sizeof(ip)),
	ip4addr_ntoa_r(&event->event_info.got_ip.ip_info.netmask, nm, sizeof(nm)),
	ip4addr_ntoa_r(&event->event_info.got_ip.ip_info.gw, gw, sizeof(gw)));
}
		send_msg();

#if DISCONNECT
		done = 1;

#if defined(GRACE_MS) && GRACE_MS > 0
Log ("delay %dms", GRACE_MS);
	delay(GRACE_MS);	// time to send UDP message
#endif

Log ("esp_wifi_disconnect");
		esp_wifi_disconnect();
#else
		finish ();
#endif
	break;
	case SYSTEM_EVENT_STA_DISCONNECTED:
Log ("SYSTEM_EVENT_STA_DISCONNECTED");

		if (done)
			finish ();
		else {
Log ("esp_wifi_connect");
			esp_wifi_connect();	// try again
		}
		break;
	default:
Log ("ignoring SYSTEM_EVENT %d", event->event_id);
		break;
	}
	return ESP_OK;
}

static void udp(void)
{
#if 000		// no effect
Log ("esp_phy_load_cal_and_init");
	esp_phy_load_cal_and_init();	// no effect
#endif
	
Log ("tcpip_adapter_init");
	tcpip_adapter_init();

Log ("esp_event_loop_init");
	esp_event_loop_init(event_handler, NULL);

Log ("esp_wifi_init");
	wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
	esp_wifi_init(&cfg);

	if (reset_reason != DEEPSLEEP_RESET) {	// this should be saved in flash
Log ("esp_wifi_set_mode");
		esp_wifi_set_mode(WIFI_MODE_STA);

		wifi_config_t wifi_config;
		memset (&wifi_config, 0, sizeof(wifi_config));
		memcpy (wifi_config.sta.ssid, AP_SSID, sizeof(wifi_config.sta.ssid));
		memcpy (wifi_config.sta.password, AP_PASS, sizeof(wifi_config.sta.password));
	
Log ("esp_wifi_set_config");
		esp_wifi_set_config(ESP_IF_WIFI_STA, &wifi_config);
	}

Log ("esp_wifi_start");
	esp_wifi_start();

Log ("udp end");
}

void app_main ()
{
//	uint64_t system_get_rtc_time(void);

	gpio_pad_select_gpio(OUT_PIN);
	gpio_set_direction(OUT_PIN, GPIO_MODE_OUTPUT);
	gpio_set_level(OUT_PIN, 1);	// mark app start

//	time_since_boot = system_get_rtc_time();
	gettimeofday (&app_start, NULL);

	gpio_pad_select_gpio(DBG_PIN);
	gpio_set_direction(DBG_PIN, GPIO_MODE_INPUT);
	gpio_pullup_en(DBG_PIN);
	do_log = gpio_get_level(DBG_PIN);

//Log ("app_main start portTICK_PERIOD_MS=%d sizeof(int)=%d sizeof(long)=%d",
//	portTICK_PERIOD_MS, sizeof(int), sizeof(long));

	wakeup_cause = rtc_get_wakeup_cause();
	reset_reason = rtc_get_reset_reason(0);

	udp();
}

