#include <stdio.h>
#include <string.h>
#include <sys/time.h>
#include <rom/rtc.h>

#include <esp_system.h>
#include <esp_err.h>

/* udp.c */
void get_time (struct timeval *now);
void delay (int ms);

/* bme280.c */
esp_err_t bme280_init (uint8_t sda, uint8_t scl, int full);
float bme280_temp (void);

int do_log;

#define LOG_FLUSH	0	// 0=no flush after each Log message

#define Dbg(f) \
do { \
	esp_err_t _ret_; \
	_ret_ = (f); \
	if (ESP_OK != _ret_) { \
		Log ("### %d: ret=%d %s", __LINE__, _ret_, #f); \
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

