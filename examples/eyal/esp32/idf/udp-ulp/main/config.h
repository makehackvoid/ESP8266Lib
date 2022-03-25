#ifndef MY_CONFIG_H
#define MY_CONFIG_H

// The numbers are the static IP LSB) of the module

#define ESP_32a 62
#define ESP_32b 64
#define ESP_32c 65
#define ESP_32d 89
#define ESP_32e 90
#define ESP_32f 91
#define ESP_32g 92
#define ESP_32h 88
#define ESP_32i 81
#define ESP_32k 82

#define MY_HOST		ESP_32k

#undef USE_DHCPC		// or define to enable

#if ESP_32a == MY_HOST
#define MY_NAME		"esp-32a"
#endif

#if ESP_32b == MY_HOST
#define MY_NAME		"esp-32b"
#endif

#if ESP_32c == MY_HOST
#define MY_NAME		"esp-32c"
#endif

#if ESP_32d == MY_HOST
#define MY_NAME		"esp-32d"
#endif

#if ESP_32e == MY_HOST
#define MY_NAME		"esp-32e"
#endif

#if ESP_32f == MY_HOST
#define MY_NAME		"esp-32f"
#endif

#if ESP_32g == MY_HOST
#define MY_NAME		"esp-32g"
#define SVR_IP		"192.168.2.87"	// dell
#define SVR_PORT	31883
#endif

#if ESP_32h == MY_HOST
#define MY_NAME		"esp-32h"
#define SVR_PORT	31883
#endif

#if ESP_32i == MY_HOST
#define MY_NAME		"esp-32i"
#define SVR_IP		"192.168.2.87"	// dell
#define SVR_PORT	31883
#endif

#if ESP_32k == MY_HOST
#define MY_NAME		"esp-32k"
//#define SVR_IP	"192.168.2.95"	// compaq
#define SVR_PORT	31883
#endif

#include "secret.h"	// defines AP_SSID and AP_PASS

#ifndef SVR_IP
#define SVR_IP		"192.168.2.7"	// e7
#endif

#ifndef SVR_PORT
#define SVR_PORT	21883
#endif

#if !defined(USE_DHCPC) && !defined(MY_SUBNET)
#define MY_SUBNET	"192.168.2"
#endif

#include "io.h"

#endif	// MY_CONFIG_H
