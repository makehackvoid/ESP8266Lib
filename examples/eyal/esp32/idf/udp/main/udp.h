#ifndef _UDP_H
#define _UDP_H

#include <stdio.h>
#include <string.h>
#include <sys/time.h>
#include <esp_system.h>
#include <esp_err.h>
#include <freertos/FreeRTOS.h>
#include <freertos/event_groups.h>

#define BAD_TEMP	85

/* udp.c */
void flush_uart (void);
void toggle(int ntimes);
void toggle_short(int ntimes);
void get_time_tv (struct timeval *now);
uint64_t gettimeofday_us(void);
int do_log;
bool woke_up;

#define LOG_FLUSH	1	// 1= flush uart after each Log message
#define LOG_ERRORS	1	// 1= always log errors

#define LogF(fmt,...) \
do { \
	struct timeval now; \
\
	get_time_tv (&now); \
	printf ("%3lu.%06lu " fmt "\n", now.tv_sec, now.tv_usec, ##__VA_ARGS__); \
	if (LOG_FLUSH) flush_uart (); \
} while (0)

#define Log(...) \
do { \
	if (do_log) \
		LogF(__VA_ARGS__); \
} while (0)

#define Mark(fmt,...) \
do { \
	Log ("### %s:%d: " fmt, __FILE__, __LINE__, ##__VA_ARGS__); \
} while (0)

#define MarkE(fmt,...) \
do { \
	if (LOG_ERRORS) \
		LogF ("### %s:%d: " fmt, __FILE__, __LINE__, ##__VA_ARGS__); \
	else \
		Log  ("### %s:%d: " fmt, __FILE__, __LINE__, ##__VA_ARGS__); \
} while (0)

#define LogR(ret,fmt,...) \
do { \
	MarkE (fmt, ##__VA_ARGS__); \
	return (ret); \
} while (0)

#define Dbg(f) \
do { \
	ret = (f); \
	if (ESP_OK != ret) \
		MarkE ("ret=%d %s", ret, #f); \
} while (0)

#define DbgR(f) \
do { \
	esp_err_t _ret_; \
	_ret_ = (f); \
	if (ESP_OK != _ret_) { \
		MarkE ("ret=%d %s", _ret_, #f); \
		return _ret_; \
	} \
} while (0)

#define USE_DELAY_BUSY	0	// TESTING

#if USE_DELAY_BUSY
void delay_us_busy (int us);
#define delay_us(us) \
do { \
	int _us_ = (us); \
	if (_us_ <= 60) \
		delay_us_busy (_us_); \
	else \
		ets_delay_us (_us_); \
} while (0)
#else
#define delay_us(us) ets_delay_us (us)
#endif

#define delay_ms(ms) \
do { \
	int __ms__ = (ms); \
	while (__ms__-- > 0) \
		delay_us (1000); \
} while (0)

#endif // _UDP_H
