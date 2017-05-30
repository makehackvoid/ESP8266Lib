#ifndef _UDP_H
#define _UDP_H

#include <stdio.h>
#include <string.h>
#include <sys/time.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <rom/rtc.h>

#include <esp_system.h>
#include <esp_err.h>

/* udp.c */
void toggle(int ntimes);
void get_time (struct timeval *now);
void delay (int ms);

int do_log;

#define LOG_FLUSH	0	// 0=no flush after each Log message

#define Dbg(f) \
do { \
	ret = (f); \
	if (ESP_OK != ret) \
		Log ("### %s:%d: ret=%d %s", __FILE__, __LINE__, ret, #f); \
} while (0)

#define DbgR(f) \
do { \
	esp_err_t _ret_; \
	_ret_ = (f); \
	if (ESP_OK != _ret_) { \
		Log ("### %s:%d: ret=%d %s", __FILE__, __LINE__, _ret_, #f); \
		return _ret_; \
	} \
} while (0)

#define Log(fmt,...) \
if (do_log) do { \
	struct timeval now; \
\
	get_time (&now); \
	printf ("%3lu.%06lu " fmt "\n", now.tv_sec, now.tv_usec, ##__VA_ARGS__); \
	if (LOG_FLUSH) fflush(stdout); \
} while (0)

#define delay_ms(ms)	vTaskDelay(ms / portTICK_PERIOD_MS)
#define delay_us(us)	ets_delay_us (us)

#endif // _UDP_H
