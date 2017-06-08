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

#define BAD_TEMP	85

/* udp.c */
void toggle(int ntimes);
void toggle_short(int ntimes);
void get_time (struct timeval *now);

int do_log;

#define LOG_FLUSH	1	// 0=no flush after each Log message

#define Log(fmt,...) \
if (do_log) do { \
	struct timeval now; \
\
	get_time (&now); \
	printf ("%3lu.%06lu " fmt "\n", now.tv_sec, now.tv_usec, ##__VA_ARGS__); \
	if (LOG_FLUSH) fflush(stdout); \
} while (0)


#define Mark(fmt,...) \
do { \
	Log ("### %s:%d: " fmt, __FILE__, __LINE__, ##__VA_ARGS__); \
} while (0)

#define Dbg(f) \
do { \
	ret = (f); \
	if (ESP_OK != ret) \
		Mark ("ret=%d %s", ret, #f); \
} while (0)


#define DbgR(f) \
do { \
	esp_err_t _ret_; \
	_ret_ = (f); \
	if (ESP_OK != _ret_) { \
		Mark ("ret=%d %s", _ret_, #f); \
		return _ret_; \
	} \
} while (0)


#define delay_us(us)	ets_delay_us (us)
#define delay_ms(ms) \
do { \
	int __ms__ = (ms); \
	while (__ms__-- > 0) \
		delay_us (1000); \
} while (0)

#endif // _UDP_H
